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

      expect(pre_assignments.size).to eq(2)

      pre_assignment = pre_assignments.first
      expect(pre_assignment.date).to eq(@piece1.created_at)
      expect(pre_assignment.pack_name).to eq('TS%0001 AC 201401')
      expect(pre_assignment.piece_counts).to eq(2)
      expect(pre_assignment.comment).to be_nil

      pre_assignment = pre_assignments.last
      expect(pre_assignment.date).to eq(@piece3.created_at)
      expect(pre_assignment.pack_name).to eq('TS%0001 AC 201402')
      expect(pre_assignment.piece_counts).to eq(1)
      expect(pre_assignment.comment).to be_nil
    end
  end
end
