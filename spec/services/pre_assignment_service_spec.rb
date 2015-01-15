# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreAssignmentService do
  describe '.pending' do
    before(:all) do
      DatabaseCleaner.start

      @user  = FactoryGirl.create :user,  code: 'TS%0001'

      Timecop.freeze(Time.local(2014,1,1,8,0,0))
      @pack = Pack.create(name: 'TS%0001 AC 201401 all', owner_id: @user.id)
      @piece1 = Pack::Piece.create(name: 'TS%0001 AC 201401 001',
                                   pack_id: @pack.id,
                                   origin: 'scan',
                                   is_awaiting_pre_assignment: true)
      @piece2 = Pack::Piece.create(name: 'TS%0001 AC 201401 002',
                                   pack_id: @pack.id,
                                   origin: 'scan',
                                   is_awaiting_pre_assignment: true)

      Timecop.freeze(Time.local(2014,2,1,8,0,0))
      @pack2 = Pack.create(name: 'TS%0001 AC 201402 all', owner_id: @user.id)
      @piece3 = Pack::Piece.create(name: 'TS%0001 AC 201402 001',
                                   pack_id: @pack2.id,
                                   origin: 'scan',
                                   is_awaiting_pre_assignment: true)

      Timecop.return
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    it 'return 2 entries' do
      pre_assignments = PreAssignmentService.pending

      pre_assignments.size.should eq(2)

      pre_assignment = pre_assignments.first
      pre_assignment.date.should eq(@piece1.created_at)
      pre_assignment.pack_name.should eq('TS%0001 AC 201401')
      pre_assignment.piece_counts.should eq(2)
      pre_assignment.comment.should be_nil

      pre_assignment = pre_assignments.last
      pre_assignment.date.should eq(@piece3.created_at)
      pre_assignment.pack_name.should eq('TS%0001 AC 201402')
      pre_assignment.piece_counts.should eq(1)
      pre_assignment.comment.should be_nil
    end

    it 'return the first comment' do
      @piece1.update_attribute(:pre_assignment_comment, 'A')
      @piece2.update_attribute(:pre_assignment_comment, 'B')

      expect(@piece1).to be_persisted
      expect(@piece2).to be_persisted

      pre_assignment = PreAssignmentService.pending.first
      pre_assignment.comment.should eq('A')
    end
  end
end
