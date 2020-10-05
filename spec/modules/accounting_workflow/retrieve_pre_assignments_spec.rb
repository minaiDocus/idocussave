# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AccountingWorkflow::RetrievePreAssignments do

  context 'Pre-assignment - preseizure' do
    def prepare_valid_xml
      @piece.update(name: @piece_name_valid.tr('_', ' '), content_file_name: "#{@piece_name_valid}.pdf")
      allow_any_instance_of(AccountingWorkflow::RetrievePreAssignments).to receive(:valid_files_path).and_return([Rails.root.join('spec/support/files/pre_assignment/output/', "#{@piece_name_valid}.xml")])
    end

    def prepare_ignored_xml
      @piece.update(name: @piece_name_ignored.tr('_', ' '), content_file_name: "#{@piece_name_ignored}.pdf")
      allow_any_instance_of(AccountingWorkflow::RetrievePreAssignments).to receive(:valid_files_path).and_return([Rails.root.join('spec/support/files/pre_assignment/output/', "#{@piece_name_ignored}.xml")])
    end

    before(:all) do
      @piece_name_valid = 'AC0089_AC_201801_001'
      @piece_name_ignored = 'AC0089_AC_201801_002'

      @organization = create :organization, code: 'IDOC'
      @user = create :user, code: 'IDOC%ALPHA'

      @period = create :period, { user: @user, organization: @organization }
      @account_book_type = create :journal_with_preassignment, { name: 'AC', user: @user, organization: @organization }
      @pack = create :pack, { name: "IDOC%ALPHA AC 201804 ALL", owner: @user, organization: @organization }
    end

    before(:each) do
      @piece = create :piece, { user: @user, organization: @organization, pack: @pack, pre_assignment_state: 'processing' }
      @piece.processing_pre_assignment

      allow(FileUtils).to receive(:mkdir_p).and_return(true)
      allow(FileUtils).to receive(:mv).and_return(true)
      allow(File).to receive(:write).and_return(true)
      allow(File).to receive(:delete).and_return(true)
      allow(FileDelivery).to receive(:prepare).and_return(true)
      allow_any_instance_of(User).to receive_message_chain("subscription.find_or_create_period").and_return(@period)
      allow_any_instance_of(AccountingWorkflow::RetrievePreAssignments).to receive(:create_preseizure).and_return(double(is_not_blocked_for_duplication: false))
    end

    after(:each) do
      @piece.destroy
    end

    it 'creates preseizure for valid pieces', :valid_piece do
      prepare_valid_xml

      AccountingWorkflow::RetrievePreAssignments.execute('preseizure')

      @piece.reload
      expect(@piece.pre_assignment_processed?).to be true
      expect(@piece.is_already_pre_assigned_with?('preseizure')).to be true
      expect(@piece.is_awaiting_pre_assignment?).to be false
      expect(@piece.pre_assignment_comment).to be nil
    end

    it 'ignores pre-assignment when piece has a ignore element value', :ignored_piece do
      prepare_ignored_xml

      AccountingWorkflow::RetrievePreAssignments.execute('preseizure')

      @piece.reload
      expect(@piece.pre_assignment_ignored?).to be true
      expect(@piece.is_awaiting_pre_assignment?).to be false
      expect(@piece.pre_assignment_comment).to_not be nil
    end

    it 'does not create preseizure when piece is already pre-assigned', :already_pre_assigned do
      prepare_valid_xml
      allow_any_instance_of(Pack::Piece).to receive(:preseizures).and_return([double(id:1), double(id:2)])

      pre_assignment = AccountingWorkflow::RetrievePreAssignments.new('preseizure')

      expect(pre_assignment).to receive(:move_and_write_errors).once
      pre_assignment.execute

      @piece.reload
      expect(@piece.pre_assignment_not_processed?).to be true
      expect(@piece.is_awaiting_pre_assignment?).to be false
    end
  end

end