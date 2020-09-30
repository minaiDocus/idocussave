# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe SgiApiServices::RetrievePreAsignmentService do
  def data_content_valid
    { "packs": [{"id": @pack.id, "name": "#{@pack.name.gsub(' all', '')}", "process": "preseizure", "pieces": [{"id": @piece1.id, "name": "#{@piece1.name}", "preseizure": [{"date": "27/09/2017", "third_party": "OVH", "piece_number": "FR21226536", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS NON TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "account": [{"type": "TTC", "number": "0DIV", "lettering": "", "debit": [{ "number": "", "value": 0}], "credit": [{ "number": "", "value": 2.78}]}, { "type": "HT", "number": "471000", "lettering": "", "debit": [{ "number": "1", "value": 2.32}], "credit": [{ "number": "", "value": 0}] }]}]}, {"id": @piece2.id, "name": "#{@piece2.name}", "preseizure": [{"date": "27/09/2018", "third_party": "OVH-3", "piece_number": "FR2122653601", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "account": [{"type": "TTC", "number": "0DIV", "lettering": "", "debit": [{ "number": "", "value": 0.46}], "credit": [{ "number": "", "value": 2.78}]}, { "type": "TVA", "number": "445660", "lettering": "", "debit": [{ "number": "1", "value": 2.32}], "credit": [{ "number": "", "value": 0}] }]}]}]}]
    }
  end

  def data_content_ignored
    { "packs": [{"id": @pack.id, "name": "#{@pack.name.gsub(' all', '')}", "process": "preseizure", "pieces": [{"id": @piece1.id, "name": "#{@piece1.name}", "ignore": "RAISON 1", "preseizure": [{"date": "27/09/2017", "third_party": "OVH", "piece_number": "FR21226536", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS NON TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "account": [{"type": "TTC", "number": "0DIV", "lettering": "", "debit": [{ "number": "", "value": 0}], "credit": [{ "number": "", "value": 2.78}]}, { "type": "HT", "number": "471000", "lettering": "", "debit": [{ "number": "1", "value": 2.32}], "credit": [{ "number": "", "value": 0}] }]}]}, {"id": @piece2.id, "name": "#{@piece2.name}", "ignore": "RAISON 2", "preseizure": [{"date": "27/09/2018", "third_party": "OVH-3", "piece_number": "FR2122653601", "amount": "", "currency": "", "conversion_rate": "", "unit": "", "deadline_date": "", "observation": "TIERS TROUVE DANS LE PLAN COMPTABLE", "is_made_by_abbyy": true, "account": [{"type": "TTC", "number": "0DIV", "lettering": "", "debit": [{ "number": "", "value": 0.46}], "credit": [{ "number": "", "value": 2.78}]}, { "type": "TVA", "number": "445660", "lettering": "", "debit": [{ "number": "1", "value": 2.32}], "credit": [{ "number": "", "value": 0}] }]}]}]}]
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
  end

  before(:each) do
    allow_any_instance_of(SgiApiServices::RetrievePreAsignmentService).to receive(:create_preseizure).and_return(double(is_not_blocked_for_duplication: false))

    allow_any_instance_of(User).to receive_message_chain("subscription.find_or_create_period").and_return(@period)

    @piece1 = create :piece, { user: @user, name: 'TS%0001 AC 202001 001', organization: @organization, pack: @pack, pack_id: @pack.id, is_awaiting_pre_assignment:  true }
    @piece2 = create :piece, { user: @user, name: 'TS%0001 AC 202001 002', organization: @organization, pack: @pack, pack_id: @pack.id, is_awaiting_pre_assignment:  true }

    @piece1.processing_pre_assignment
    @piece2.processing_pre_assignment
  end

  after(:each) do
    @piece1.destroy
    @piece2.destroy
  end

  describe 'retrieve preassignment sending' do
    it "pack not exist, process interrupted" do
      allow(Pack).to receive(:find).with(any_args).and_return([])
      expect(Reporting).not_to receive(:find_or_create_period_document).with(any_args)

      list_pieces = SgiApiServices::RetrievePreAsignmentService.new(data_content_valid.with_indifferent_access).execute

      expect(list_pieces.size).to eq 0
    end

    it "creates preseizure for valid pieces" do
      list_pieces = SgiApiServices::RetrievePreAsignmentService.new(data_content_valid.with_indifferent_access).execute

      expect(list_pieces.size).to eq 2
      @piece1.reload

      expect(@piece1.pre_assignment_processed?).to be true
      expect(@piece1.is_already_pre_assigned_with?('preseizure')).to be true
      expect(@piece1.is_awaiting_pre_assignment).to be false
      expect(@piece1.pre_assignment_comment).to be nil

      expect(list_pieces.first[:id]).to eq @piece1.id
      expect(list_pieces.first[:name]).to eq @piece1.name

      expect(list_pieces.last[:id]).to eq @piece2.id
      expect(list_pieces.last[:name]).to eq @piece2.name
    end

    it 'ignores pre-assignment when piece has a ignore element value', :ignore do
      list_pieces = SgiApiServices::RetrievePreAsignmentService.new(data_content_ignored.with_indifferent_access).execute

      @piece1.reload

      expect(@piece1.pre_assignment_ignored?).to be true
      expect(@piece1.is_awaiting_pre_assignment).to be false
      expect(@piece1.pre_assignment_comment).to_not be nil
    end

    it 'does not create preseizure when piece is already pre-assigned' do
      allow_any_instance_of(Pack::Piece).to receive(:preseizures).and_return([double(id:1), double(id:2)])

      list_pieces = SgiApiServices::RetrievePreAsignmentService.new(data_content_valid.with_indifferent_access).execute

      @piece1.reload

      expect(@piece1.pre_assignment_not_processed?).to be true
      expect(@piece1.is_awaiting_pre_assignment).to be false
    end
  end
end