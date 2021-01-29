# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Api::Sgi::V1::PreassignmentController do
  render_views

  def temp_document
    temp_document = TempDocument.new
    temp_document.temp_pack      = @temp_pack
    temp_document.user           = @user
    temp_document.position       = 1
    temp_document.pages_number   = 2
    temp_document.is_an_original = true
    temp_document.is_a_cover     = false
    temp_document.state          = 'bundle_needed'
    temp_document.save

    temp_document
  end

  def data_content
    {
      process: "preseizure",
      pack_name: "#{@pack.name.gsub(' all', '')}",
      piece_id: @piece1.id,
      preseizures: [
        {"date": "27/09/2017", "third_party": "OVH", "piece_number": "FR21226536", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS NON TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "accounts": [{"type": "TTC", "number": "0DIV", "lettering": "", "amount": { "type": "credit", "number": "", "value": 2.78}}, { "type": "HT", "number": "471000", "lettering": "", "amount": { "type": "debit", "number": "1", "value": 2.32}} ]},

       {"date": "27/09/2017", "third_party": "OVH", "piece_number": "FR21226536", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS NON TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "accounts": [{"type": "TTC", "number": "0DIV", "lettering": "", "amount": { "type": "credit", "number": "", "value": 2.78}}, { "type": "HT", "number": "471000", "lettering": "", "amount": { "type": "debit", "number": "1", "value": 2.32}} ]}
      ]
    }
  end

  before(:all) do
    @organization = create :organization, code: 'IDOC'
    @organization2 = create :organization, code: 'TEEO'
    @organization3 = create :organization, code: 'GMBA'

    @user = create :user, :admin, code: 'IDOC%ALPHA', organization: @organization
    @user2 = create :user, :admin, code: 'TEEO%0001', organization: @organization2
    @user3 = create :user, :admin, code: 'GMBA%0001', organization: @organization3

    @user.update_authentication_token
    @user2.update_authentication_token
    @user3.update_authentication_token

    @pack = create :pack, { name: "IDOC%ALPHA AC 201804 ALL", owner: @user, organization: @organization }
    @pack2 = create :pack, { name: "TEEO%0001 AC 201804 ALL", owner: @user2, organization: @organization2 }
    @pack3 = create :pack, { name: "GMBA%0001 AC 201804 ALL", owner: @user3, organization: @organization3 }

    @temp_pack = create :temp_pack, user: @user, organization: @organization, name: @pack.name
    @temp_pack2 = create :temp_pack, user: @user2, organization: @organization2, name: @pack2.name
    @temp_pack3 = create :temp_pack, user: @user2, organization: @organization2, name: @pack3.name

    @journal = create :account_book_type, user: @user, entry_type: 2, name: @temp_pack.name.split[1], account_number: "FREAFFECT", charge_account: "65899999", anomaly_account: "FANOMALIE"
    @journal2 = create :account_book_type, user: @user2, entry_type: 2, name: @temp_pack2.name.split[1], account_number: "FREAFFECTEEO", charge_account: "65899988", anomaly_account: "FANOMALIEEO"

    @period = create :period, { user: @user, organization: @organization }

    @piece1 = create :piece, { user: @user, name: 'TS%0001 AC 202001 001', organization: @organization, pack: @pack, pack_id: @pack.id, pre_assignment_state: "waiting" }
    @piece2 = create :piece, { user: @user, name: 'TS%0001 AC 202001 002', organization: @organization, pack: @pack, pack_id: @pack.id, pre_assignment_state: "waiting" }
    @piece3 = create :piece, { user: @user, name: 'TEEO%0001 AC 202001 002', organization: @organization2, pack: @pack2, pre_assignment_state: "waiting" }
    @piece4 = create :piece, { user: @user3, name: 'GMBA%0001 AC 202001 002', organization: @organization3, pack: @pack3, pre_assignment_state: "waiting" }
  end

  before(:each) do
    allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
  end

  context "get list pieces", :list_piece do
    it 'no preassignment needed pieces'do
      allow(Pack::Piece).to receive(:need_preassignment).and_return([])
      expect(TempPack).to receive(:find_by_name).with(any_args).exactly(0).times

      get :preassignment_needed, format: :json, params: { :compta_type => "AC", :access_token => @user.authentication_token }

      expect(response).to be_successful

      result = JSON.parse(response.body)

      expect(result["pieces"].size).to eq 0
    end

    it 'get preassignment needed pieces TEEO', :piece_teeo do
      allow(Pack::Piece).to receive(:need_preassignment).and_return([@piece3, @piece2])
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(temp_document)

      get :preassignment_needed, format: :json, params: { :compta_type => "TEEO", :access_token => @user.authentication_token }

      result = JSON.parse(response.body)

      expect(response).to be_successful
      expect(result["pieces"].size).to eq 1
      expect(result["pieces"].first["piece_name"]).to eq @piece3.name
      expect(result["pieces"].first["compta_type"]).to eq "AC"
      expect(result["pieces"].first["detected_third_party_id"]).to eq 6930
    end

    it "get list pieces exactly pieces1 and piece2 with compta_type AC", :ac do
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(temp_document)

      get :preassignment_needed, format: :json, params: { :compta_type => "AC", :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)
      expect(result["pieces"].size).to eq 2
      expect(result["pieces"].first["piece_name"]).to eq @piece1.name
      expect(result["pieces"].first["compta_type"]).to eq "AC"
      expect(result["pieces"].first["detected_third_party_id"]).to eq 6930
      expect(result["pieces"].last["piece_name"]).to eq @piece2.name
      expect(result["pieces"].last["compta_type"]).to eq "AC"
      expect(result["pieces"].last["detected_third_party_id"]).to eq 6930
    end

    it "get list pieces exactly pieces1 and piece2 with compta_type NDF" do
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(temp_document)

      get :preassignment_needed, format: :json, params: { :compta_type => "NDF", :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)
      expect(result["pieces"].size).to eq 0
    end

    it "get list pieces with unknown compta_type" do
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(temp_document)

      get :preassignment_needed, format: :json, params: { :compta_type => "MUS", :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)
      expect(result["error_message"]).to eq "Compta type non reconnu"
    end

    it "send notif error if piece have an error condition" do
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(nil)

      get :preassignment_needed, format: :json, params: { :compta_type => "AC", :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)
      expect(result["pieces"].size).to eq 0
    end

    it 'get list pieces with an error', :error do
      allow(Pack::Piece).to receive(:need_preassignment).and_return([@piece4, @piece2])
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(temp_document)

      get :preassignment_needed, format: :json, params: { :compta_type => "AC", :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)

      expect(result["pieces"].size).to eq 1
      expect(result["errors"].size).to eq 1
      expect(result["errors"].first["error_message"]).to eq 'Pas de journal correspondant à AC'
      expect(result["errors"].first["piece_id"]).to eq @piece4.id
    end
  end

  context "download piece", :download_piece do
    it "download piece success with id" do
      url = @piece1.get_access_url
      get :download_piece, format: :json, params: { :access_token => @user.authentication_token, :piece_id => @piece1.id }

      expect(response).to be_successful
      result = JSON.parse(response.body)

      expect(result["url_piece"]).to eq Domains::BASE_URL + url
    end

    it "download piece failed because id nil" do
      get :download_piece, format: :json, params: { :access_token => @user.authentication_token }

      expect(response.status).to eq 601
      result = JSON.parse(response.body)

      expect(result["message"]).to eq "Id pièce absent"
    end
  end

  context "process preassignment", :pre_assignment do
    it "try to send with params data" do
      results = [{ id: @piece1.id, name: @piece1.name }, { id: @piece2.id, name: @piece2.name }]
      allow_any_instance_of(SgiApiServices::PushPreAsignmentService).to receive(:execute).and_return(results)

      post :push_preassignment, format: :json, params: {:piece_id => @piece1.id, :access_token => @user.authentication_token, data_preassignments: data_content }

      expect(response).to be_successful
      result = JSON.parse(response.body)

      expect(result["results"].size).to eq 2
      expect(result["results"].first['id']).to eq @piece1.id
      expect(result["results"].first['name']).to eq @piece1.name
    end

    it "try to send without params data", :test do
      post :push_preassignment, format: :json, params: { :access_token => @user.authentication_token, :piece_id => @piece1.id }

      expect(response.status).to eq 601
      result = JSON.parse(response.body)

      expect(result["message"]).to eq "Paramètre absent"
    end

    it 'update teeo piece to processed', :teeo do
      @piece1.reload.waiting_pre_assignment

      post :update_teeo_pieces, format: :json, params: {:piece_ids => [@piece1.id], :access_token => @user.authentication_token}

      expect(response.status).to eq 200
      expect(@piece1.reload.pre_assignment_processed?).to eq true
    end
  end
end