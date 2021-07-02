# -*- encoding : UTF-8 -*-
require 'spec_helper'

Sidekiq::Testing.inline! #execute jobs immediatly

describe Api::Sgi::V1::JefactureController, :type => :controller do
  before(:all) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2021,06,8))

    organization = FactoryBot.create :organization, code: 'IDO'
    @admin = FactoryBot.create :user, :admin, code: 'IDO%0001', organization_id: organization.id
    @token = 'Token 123'
    @admin.authentication_token = @token 
    @admin.save

    @pack = create :pack, { name: 'IDO%0001 AC 202106 all', owner: @admin, organization: organization }

    # Subscription.create(period_duration: 1, tva_ratio: 1.2, user_id: nil, organization_id: organization.id)
    Subscription.create(period_duration: 1, current_packages: '["ido_classique", "pre_assignment_option"]', number_of_journals: 5, organization_id: nil, user_id: @admin.id)

    FactoryBot.create(:account_book_type, :journal_with_preassignment, user_id: @admin.id, name: 'AC', description: '( Achat )')
    file_upload = Rails.root.join('spec', 'support', 'files', 'upload.pdf')

    CustomUtils.mktmpdir('jefacture_validation') do |dir|
      @temp_pack = TempPack.find_or_create_by_name @pack.name
      file_name = 'IDO_0001_AC_202106.pdf'
      file_path = File.join dir, file_name
      FileUtils.cp file_upload, file_path
      options = {
        original_file_name: file_name,
        delivered_by: 'test',
        delivery_type: 'upload',
        is_content_file_valid: true
      }
      AddTempDocumentToTempPack.execute(@temp_pack, open(file_path), options)
    end


    @period = create :period, { user: @admin, organization: organization }

    @piece = create :piece, { user: @admin, name: 'IDO%0001 AC 202106 001', organization: organization, pack: @pack, pack_id: @pack.id, pre_assignment_state: "ready" }

    report = Pack::Report.create(organization: @piece.user.organization, user: @piece.user, type: 'FLUX', name: @piece.pack.name.sub(' all', ''))

    @raw_preseizure = {
      "piece_number"=>"8371145",
      "amount"=>14.15,
      "currency"=>"EUR",
      "unit"=>"EUR",
      "conversion_rate"=>nil,
      "third_party"=>"FIDUCIAL BUREAUTIQUE",
      "date"=>"2021-06-03",
      "deadline_date"=>"2021-06-03",
      "observation"=>"MADE BY JEFACTURE",
      "position"=>nil,
      "is_made_by_abbyy"=>false,
      "entries"=>[
        {"type"=>1, "account_type"=>3, "account"=>"445660", "amount"=>2.36},
        {"type"=>1, "account_type"=>2, "account"=>"606400", "amount"=>11.79},
        {"type"=>2, "account_type"=>1, "account"=>"FFID", "amount"=>14.15}
      ]}.with_indifferent_access

      @piece_params = { 
        piece_id: @piece.id,
        piece_name: @piece.name,
        piece_url: Domains::BASE_URL + @piece.try(:get_access_url),
        compta_type: @piece.user.account_book_types.where(name: @piece.journal).first&.compta_type,
        pack_name: @temp_pack.name,
        detected_third_party_id: (@piece.detected_third_party_id.presence || 6930)
      }.with_indifferent_access

    Pack::Report::TempPreseizure.create(
      raw_preseizure: @raw_preseizure,
      is_made_by_abbyy: true,
      organization_id: organization.id, user_id: @admin.id, report_id: report.id, piece_id: @piece.id, position: @piece.position, state: 'created'
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "GET waiting_validation jefacture", :waiting_validation do
    it "with success: true, data size equal 1 and message to be nil" do
      temp_preseizure = Pack::Report::TempPreseizure.last

      temp_preseizure.waiting_validation

      get :waiting_validation, format: :json, params: {:access_token => @token}
      json_response = JSON.parse(response.body)

      result = json_response["data"]

      expect(response).to have_http_status(:ok)
      expect(result.size).to eq 1
      expect(result.first['temp_preseizure_id']).to eq temp_preseizure.id
      expect(result.first['piece_id']).to eq @piece_params['piece_id']
      expect(result.first['piece_name']).to eq @piece_params['piece_name']
      expect(result.first['detected_third_party_id']).to eq @piece_params['detected_third_party_id']
      expect(result.first['third_party']).to eq @raw_preseizure['third_party']
      expect(result.first['entries']).to eq @raw_preseizure['entries']

      expect(json_response.keys).to match_array(["success", "data", "message"])
      expect(json_response["success"]).to be true
      json_response[ "data" ].each do |status|
        expect(status.keys).to contain_exactly( 
          "third_party", "entries", "temp_preseizure_id", "piece_id", "piece_name", "detected_third_party_id",
          "piece_url", "compta_type", "pack_name"
        )
      end
    end


    it "with success: false, data size equal 0 and message to be 'Aucune pièce à valider'" do
      temp_preseizure = Pack::Report::TempPreseizure.last

      temp_preseizure.is_valid

      get :waiting_validation, format: :json, params: {:access_token => @token}
      json_response = JSON.parse(response.body)

      expect(json_response['success']).to eq false
      expect(json_response["data"].size).to eq 0
      expect(json_response['message']).to eq 'Aucune pièce à valider'
    end
  end


  context "POST pre_assigned jefacture", :pre_assigned do
    it "post params, (with allow any instance of) returns a status: 200, success: true and message: nil" do
      request.headers["ACCEPT"]        = "application/json"
      request.headers["CONTENT_TYPE"]  = "application/json"
      request.headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Token.encode_credentials(@token)

      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(TempDocument.last)

      temp_preseizure = Pack::Report::TempPreseizure.last

      temp_preseizure.waiting_validation

      data_validated = [{
        piece_id: @piece.id, temp_preseizure_id: 1, third_party: 'FIDUCIAL BUREAUTIQUE', entries: @raw_preseizure['entries']
      },]

      post :pre_assigned, format: :json, params: {:data_validated => data_validated}

      before_staff_state = temp_preseizure.reload

      staffing_before = StaffingFlow.last

      StaffingFlow.ready_jefacture.each do |sf|
        Staffingflow::JefactureWorker::Launcher.process(sf.id)
      end

      final_state = temp_preseizure.reload

      preseizure = Pack::Report::Preseizure.last

      json_response = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(json_response.keys).to match_array(["success", "results"])
      expect(json_response["success"]).to be true
      expect(json_response["results"]).to eq [{"piece_id"=>2, "piece_name"=>"IDO%0001 AC 202106 001", "temp_preseizure_id"=>1, "message"=>"Pré-affectation de jefacture corrigée", "errors"=>[]}]
      expect(json_response["results"].first['errors'].empty?).to be true

      expect(staffing_before.kind).to eq 'jefacture'
      expect(staffing_before.params[:piece_id]).to eq @piece.id

      expect(final_state.state).to eq 'cloned'

      expect(preseizure.user).to eq @admin
      expect(preseizure.organization).to eq @admin.organization
      expect(preseizure.date).to eq '2021-06-03 00:00:00.000000000 +0200'
      expect(preseizure.third_party).to eq @raw_preseizure['third_party']
      expect(preseizure.observation).to eq @raw_preseizure['observation']
      expect(preseizure.piece.pre_assignment_state).to eq 'processed'
      expect(preseizure.cached_amount).to eq @raw_preseizure['amount']

      expect(preseizure.accounts.size).to eq 3
      expect(preseizure.entries.size).to eq 3
      expect(preseizure.accounts.last.number).to eq @raw_preseizure['entries'].last['account']
      expect(preseizure.entries.last.type).to eq @raw_preseizure['entries'].last['type']
    end
  end
end