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

    CustomUtils.mktmpdir do |dir|
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
      pack_name: 'IDO%0001 AC 202006',
      pieces: [
         [
           {
             id: 2,
             pages: [2]
           }
         ],
         [
           {
             id: 4,
             pages: [1,3]
           },
           {
             id: 3,
             pages: [2]
           }
         ],
         [
           {
             id: 5,
             pages: [3]
           },
           {
             id: 5,
             pages: [1, 2]
           }
         ]
      ]
    }


    @errors_messages = {
      success: false,
      'pack_name_unknown' =>  'Pack name : IDO%0001 AC 202006 all, unknown.',
      'piece_already_bundled' => 'Piece already bundled with an id : 2 in pack name: IDO%0001 AC 202006 all.',
      'parent_temp_document_unknown' => 'Unknown temp document with an id: 2 in pack name: IDO%0001 AC 202006 all.'
    }
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "GET bundle_needed documents", :bundling_documents do
    it "valid Authorization header, returns a 200" do
      request.headers["ACCEPT"]             = "application/json"
      request.headers["CONTENT_TYPE"]       = "application/json"
      request.headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Token.encode_credentials(@token)
      get :bundle_needed, format: :json, params: {:delivery_type => 'upload'}

      expect(response).to have_http_status(:ok)
    end

    it "invalid Authorization header, returns a 401" do
      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "application/json"
      get :bundle_needed, format: :json, params: {:delivery_type => 'upload'}

      expect(response).to have_http_status(:unauthorized)
    end

    it "with delivery type equals to 'upload'" do
      @temp_pack.temp_documents.each(&:bundle_needed)

      @temp_pack.update_attributes(updated_at: 20.minutes.ago)

      get :bundle_needed, format: :json, params: {:access_token => @token, :delivery_type => 'upload'}
      json_response = JSON.parse(response.body)

      result = json_response["bundling_documents"]

      expect(result.size).to eq 1
      expect(result.first['delivery_type']).to eq 'upload'
      expect(result.first['base_file_name']).to eq 'IDO_0001_AC_202006_003'

      expect(json_response.keys).to match_array(["success", "bundling_documents"])
      expect(json_response["success"]).to be true
      json_response[ "bundling_documents" ].each do |status|
        expect(status.keys).to contain_exactly( "base_file_name", "delivery_type", "id", "temp_document_url", "temp_pack_name" )
      end
    end

    it "with delivery type equals to 'scan'" do
      @temp_pack.temp_documents.each(&:bundle_needed)

      @temp_pack.update_attributes(updated_at: 20.minutes.ago)

      get :bundle_needed, format: :json, params: {:access_token => @token, :delivery_type => 'scan'}
      json_response = JSON.parse(response.body)

      result = json_response["bundling_documents"]

      expect(result.size).to eq 2
      expect(result.first['delivery_type']).to eq 'scan'
      expect(result.first['base_file_name']).to eq 'IDO_0001_AC_202006_001'
      expect(result.second['base_file_name']).to eq 'IDO_0001_AC_202006_002'

      expect(json_response.keys).to match_array(["success", "bundling_documents"])
      expect(json_response["success"]).to be true
      json_response[ "bundling_documents" ].each do |status|
        expect(status.keys).to contain_exactly( "base_file_name", "delivery_type", "id", "temp_document_url", "temp_pack_name" )
      end
    end

    it "with delivery type equals to 'dematbox_scan'" do
      @temp_pack.temp_documents.each(&:bundle_needed)

      @temp_pack.update_attributes(updated_at: 20.minutes.ago)

      request.headers["ACCEPT"]             = "application/json"
      request.headers["CONTENT_TYPE"]       = "application/json"
      request.headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Token.encode_credentials(@token)

      get :bundle_needed, format: :json, params: {:delivery_type => 'dematbox_scan'}
      json_response = JSON.parse(response.body)

      result = json_response["bundling_documents"]

      expect(result.size).to eq 1
      expect(result.first['delivery_type']).to eq 'dematbox_scan'
      expect(result.first['base_file_name']).to eq 'IDO_0001_AC_202006_004'

      expect(json_response.keys).to match_array(["success", "bundling_documents"])
      expect(json_response["success"]).to be true
      json_response[ "bundling_documents" ].each do |status|
        expect(status.keys).to contain_exactly( "base_file_name", "delivery_type", "id", "temp_document_url", "temp_pack_name" )
      end
    end
  end

  context "POST bundled documents", :bundled_documents do
    it "post params, (with allow any instance of) returns a status: 200, success: true and message: nil" do
      allow_any_instance_of(SgiApiServices::GroupDocument).to receive(:execute).and_return(success: true)

      post :bundled, format: :json, params: {:access_token => @token, :bundled_documents => @bundled_documents}

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.keys).to match_array(["success", "message"])
      expect(json_response["success"]).to be true
      expect(json_response["message"].empty?).to be true
      expect(json_response["message"]).to eq ''
    end

    it "post params, (with real case) returns a status: 200, success: true and message: nil" do
      @temp_pack.temp_documents.each(&:bundle_needed)

      request.headers["ACCEPT"]             = "application/json"
      request.headers["CONTENT_TYPE"]       = "application/json"
      request.headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Token.encode_credentials(@token)
      post :bundled, format: :json, params: {:bundled_documents => @bundled_documents}

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.keys).to match_array(["success", "message"])
      expect(json_response["success"]).to be true
      expect(json_response["message"].empty?).to be true
      expect(json_response["message"]).to eq ''

      new_temp_documents = @temp_pack.temp_documents.where(content_file_name: "IDO%0001_AC_202006_all")
      expect(@temp_pack.temp_documents.count).to eq 9
      expect(@temp_pack.temp_documents.bundled.count).to eq 4
      expect(@temp_pack.temp_documents.ready.count).to eq 5
      expect(DocumentTools.pages_number(new_temp_documents.first.cloud_content_object.path)).to eq 1
      expect(DocumentTools.pages_number(new_temp_documents.last.cloud_content_object.path)).to eq 2
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
