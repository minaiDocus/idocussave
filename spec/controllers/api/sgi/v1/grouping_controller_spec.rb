# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Api::Sgi::V1::GroupingController, :type => :controller do
  before(:all) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,06,10))

    organization = FactoryBot.create :organization, code: 'IDO'
    @admin = FactoryBot.create :user, :admin, code: 'IDO%0001', organization_id: organization.id
    @token = 'Token 123'
    @admin.authentication_token = @token 
    @admin.save

    FactoryBot.create(:account_book_type, :journal_with_preassignment, user_id: @admin.id, name: 'AC', description: '( Achat )')
    file_with_2_pages = Rails.root.join('spec', 'support', 'files', '2pages.pdf')
    file_with_3_pages = Rails.root.join('spec', 'support', 'files', '3pages.pdf')

    Dir.mktmpdir do |dir|
      @temp_pack = TempPack.find_or_create_by_name 'IDO%0001 AC 202006 all'
      2.times do |i|
        file_name = "IDO_0001_AC_202006_%03d.pdf" % (i+1)
        file_path = File.join dir, file_name
        FileUtils.cp file_with_2_pages, file_path
        options = {
          original_file_name: file_name,
          delivered_by: 'test',
          delivery_type: 'scan',
          is_content_file_valid: true
        }

        AddTempDocumentToTempPack.execute(@temp_pack, open(file_path), options)
      end

      file_name = 'IDO_0001_AC_202006.pdf'
      file_path = File.join dir, file_name
      FileUtils.cp file_with_3_pages, file_path
      options = {
        original_file_name: file_name,
        delivered_by: 'test',
        delivery_type: 'upload',
        is_content_file_valid: true
      }
      AddTempDocumentToTempPack.execute(@temp_pack, open(file_path), options)

      options = {
        delivered_by:          'test',
        delivery_type:         'dematbox_scan',
        dematbox_doc_id:       'doc_id',
        dematbox_box_id:       'box_id',
        dematbox_service_id:   'service_id',
        dematbox_text:         'text',
        is_content_file_valid: true
      }
      AddTempDocumentToTempPack.execute(@temp_pack, open(file_path), options)
    end

    @bundled_documents = {
      "packs": [
        {
          "id": 1,
          "name": "IDO%0001 AC 202006 all",
          "pieces": [
            {
              "id": 1,
              "file_name": "IDO_0001_AC_202006_001",
              "original": "scan",
              "piece_url": "https://my.idocus.com/account/documents/pieces/2559604/download/original?token=244owwqjv0ifxqmaqfclx85srtafsyth1r1mrzepsep7me2ccm"
            },
            {
              "id": 2,
              "file_name": "IDO_0001_AC_202006_002",
              "original": "scan",
              "piece_url": "https://my.idocus.com/account/documents/pieces/2559612/download/original?token=h86h38dkd5fy4oup49d9nffvau5jgpuhwynkejupzjjx9ithe6"
            },
            {
              "id": 3,
              "file_name": "IDO_0001_AC_202006_003",
              "original": "upload",
              "piece_url": "https://my.idocus.com/account/documents/pieces/2559605/download/original?token=cnffqr74zhaa89e8hajbengb1m0b6yvr59zetgps3020omfffn"
            },
            {
              "id": 4,
              "file_name": "IDO_0001_AC_202006_004",
              "original": "dematbox_scan",
              "piece_url": "https://my.idocus.com/account/documents/pieces/2559611/download/original?token=s2vpt8vi9fmhzq51vkz4rcnenbs6hl7poqk6yuseowp8os9ebu"
            }
          ]
        }
      ]
    }


    @errors_messages = {
      success: false,
      'pack_name_unknown_with_pack_id_1' =>  'Pack name : "IDO%0001 AC 202006 all", unknown.',
      'piece_origin_unknown_with_piece_id_1' => 'Piece origin : "scan", unknown.',
      'file_name_does_not_match_origin_with_piece_id_2' => 'File name : "IDO_0001_AC_202006_002", does not match origin : "scan".',
      'file_name_does_not_match_origin_with_piece_id_1' => 'File name : "IDO_0001_AC_202006_001", does not match origin : "scan".',
      'file_name_already_grouped_with_piece_id_4' => 'File name : "IDO_0001_AC_202006_004", already grouped.',
      'undownloadable_file_for_piece_id_1' => 'File name : "IDO_0001_AC_202006_001.pdf" and piece_url: "http://localhost:3000/account/documents/pieces/1/download/original?token=arq4s5fy0vsna0kkwv4gmz9jawmoliftgxup5b56hii7jd1pw0", not found.',
      'file_name_unknown_with_piece_id_3' => 'File name : "IDO_0001_AC_202006_003", unknown.'
    }
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "GET bundle_needed documents", :bundle_needed_documents do
    it "valid Authorization header, returns a 200" do
      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "application/json"
      get :bundle_needed, format: :json, params: {:access_token => @token}

      expect(response).to have_http_status(:ok)
    end

    it "invalid Authorization header, returns a 401" do
      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "application/json"
      get :bundle_needed, format: :json, params: {:access_token => nil}

      expect(response).to have_http_status(:unauthorized)
    end
    
    it "JSON body response contains expected temp document attributes" do
      @temp_pack.temp_documents.each(&:bundle_needed)

      @temp_pack.update_attributes(updated_at: 20.minutes.ago)

      get :bundle_needed, format: :json, params: {:access_token => @token}
      json_response = JSON.parse(response.body)

      expect(json_response.keys).to match_array(["success", "bundle_needed_documents"])
      expect(json_response["success"]).to be true
      JSON.parse(json_response[ "bundle_needed_documents" ]).each do |status|
        expect(status.keys).to contain_exactly( "base_file_name", "delivery_type", "id", "temp_document_url", "temp_pack_name" )
      end
    end
  end

  context "POST bundled documents", :bundled_documents do
    it "post params, returns a status: 200, success: true and message: nil" do
      allow_any_instance_of(SgiApiServices::GroupDocument).to receive(:execute).and_return(success: true)

      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "application/json"
      post :bundled, format: :json, params: {:access_token => @token, :bundled_documents => @bundled_documents}

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.keys).to match_array(["success", "message"])
      expect(json_response["success"]).to be true
      expect(json_response["message"].empty?).to be true
      expect(json_response["message"]).to eq ''
    end
    
    it "post params, returns a status: 601, success: false and with errors messages" do
      allow_any_instance_of(SgiApiServices::GroupDocument).to receive(:execute).and_return(@errors_messages)

      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "application/json"
      post :bundled, format: :json, params: {:access_token => @token, :bundled_documents => @bundled_documents}

      expect(response).to have_http_status(601)
      json_response = JSON.parse(response.body)
      expect(json_response.keys).to match_array(["success", "message"])
      expect(json_response["success"]).to be false
      expect(json_response["message"].empty?).to be false
      expect(JSON.parse(json_response["message"])).to eq @errors_messages.with_indifferent_access
    end
  end
  
end
