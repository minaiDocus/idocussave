# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Api::Sgi::V1::SendPieceToPreassignmentController do
  render_views

  def temp_document
    temp_document = TempDocument.new
    temp_document.temp_pack      = @temp_pack
    temp_document.user           = @user
    temp_document.position       = 1
    temp_document.pages_number   = 2
    temp_document.is_an_original = true
    temp_document.is_a_cover     = false
    temp_document.state          = 'bundling'
    temp_document.save

    temp_document
  end

  def data_content
    { "packs": [{"id": @pack.id, "name": "#{@pack.name.gsub(' all', '')}", "process": "preseizure", "pieces": [{"id": @piece1.id, "name": "#{@piece1.name}", "preseizure": [{"date": "27/09/2017", "third_party": "OVH", "piece_number": "FR21226536", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS NON TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "account": [{"type": "TTC", "number": "0DIV", "lettering": "", "debit": [{ "number": "", "value": 0}], "credit": [{ "number": "", "value": 2.78}]}, { "type": "HT", "number": "471000", "lettering": "", "debit": [{ "number": "1", "value": 2.32}], "credit": [{ "number": "", "value": 0}] }]}]}, {"id": @piece2.id, "name": "#{@piece2.name}", "preseizure": [{"date": "27/09/2018", "third_party": "OVH-3", "piece_number": "FR2122653601", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "account": [{"type": "TTC", "number": "0DIV", "lettering": "", "debit": [{ "number": "", "value": 0.46}], "credit": [{ "number": "", "value": 2.78}]}, { "type": "TVA", "number": "445660", "lettering": "", "debit": [{ "number": "1", "value": 2.32}], "credit": [{ "number": "", "value": 0}] }]}]}]}]
    }
  end

  before(:all) do
    @organization = create :organization, code: 'IDOC'
    @user = create :user, :admin, code: 'IDOC%ALPHA', organization: @organization
    @user.update_authentication_token

    @pack = create :pack, { name: "IDOC%ALPHA AC 201804 ALL", owner: @user, organization: @organization }

    @temp_pack = create :temp_pack, user: @user, organization: @organization, name: @pack.name

    @journal = create :account_book_type, user: @user, entry_type: 1, name: @temp_pack.name.split[1]

    @period = create :period, { user: @user, organization: @organization }

    @piece1 = create :piece, { user: @user, name: 'TS%0001 AC 202001 001', organization: @organization, pack: @pack, pack_id: @pack.id, is_awaiting_pre_assignment:  false, pre_assignment_state: "waiting" }
    @piece2 = create :piece, { user: @user, name: 'TS%0001 AC 202001 002', organization: @organization, pack: @pack, pack_id: @pack.id, is_awaiting_pre_assignment:  false, pre_assignment_state: "waiting" }
  end

  context "get list pieces", :list_piece do
    it 'no piece for preassignmlent needed'do
      allow(Pack::Piece).to receive(:need_preassignment).and_return([])
      expect(TempPack).to receive(:find_by_name).with(any_args).exactly(0).times

      get :piece_preassignment_needed, format: :json, params: { :access_token => @user.authentication_token }

      expect(response).to be_successful

      result = JSON.parse(response.body)

      expect(result["list_url"].size).to eq 0
    end

    it "get list pieces exactly pieces1 and piece2" do
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(temp_document)
      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')

      get :piece_preassignment_needed, format: :json, params: { :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)
      expect(result["list_url"].size).to eq 2
      expect(result["list_url"].first["piece_name"]).to eq @piece1.name
      expect(result["list_url"].last["piece_name"]).to eq @piece2.name
    end

    it "send notif error if piece have an error condition" do
      allow_any_instance_of(Pack::Piece).to receive(:temp_document).and_return(nil)
      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')

      get :piece_preassignment_needed, format: :json, params: { :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)
      expect(result["list_url"].size).to eq 0
    end
  end

  context "download piece" do
    it "download piece success with id" do
      url = @piece1.get_access_url
      get :download_piece, format: :json, params: { :access_token => @user.authentication_token, :piece_id => @piece1.id }

      expect(response).to be_successful
      result = JSON.parse(response.body)

      expect(result["url_piece"]).to eq "https://my.idocus.com#{url}"
    end

    it "download piece failed because id nil" do
      get :download_piece, format: :json, params: { :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)

      expect(result["message"]).to eq "Id pièce absent"
    end
  end

  context "preassignment process", :pre_assignment do
    it "try to send with params data" do
      list_ids_piece_update = [{ id: @piece1.id, name: @piece1.name }, { id: @piece2.id, name: @piece2.name }]
      allow_any_instance_of(SgiApiServices::RetrievePreAsignmentService).to receive(:execute).and_return(list_ids_piece_update)

      post :retrieve_preassignment, format: :json, params: { :access_token => @user.authentication_token, data_preassignments: data_content }

      expect(response).to be_successful
      result = JSON.parse(response.body)

      expect(result["list_ids_piece_update"].size).to eq 2
      expect(result["list_ids_piece_update"].first['id']).to eq @piece1.id
      expect(result["list_ids_piece_update"].first['name']).to eq @piece1.name
    end

    it "try to send without params data" do
      post :retrieve_preassignment, format: :json, params: { :access_token => @user.authentication_token }

      expect(response).to be_successful
      result = JSON.parse(response.body)

      expect(result["message"]).to eq "Data absent"
    end
  end
end