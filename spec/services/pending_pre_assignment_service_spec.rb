# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PendingPreAssignmentService do
  describe '.pending' do
    before(:all) do
      @user  = FactoryBot.create :user,  code: 'TS%0001'

      Timecop.freeze(Time.local(2014,1,1,8,0,0))
      @pack = Pack.create(name: 'TS%0001 AC 201401 all', owner_id: @user.id)
      @piece1 = Pack::Piece.create(name: 'TS%0001 AC 201401 001',
                                   pack_id: @pack.id,
                                   origin: 'scan',
                                   pre_assignment_state: 'processing')
      @piece2 = Pack::Piece.create(name: 'TS%0001 AC 201401 002',
                                   pack_id: @pack.id,
                                   origin: 'scan',
                                   pre_assignment_state: 'processing')

      Timecop.freeze(Time.local(2014,2,1,8,0,0))
      @pack2 = Pack.create(name: 'TS%0001 AC 201402 all', owner_id: @user.id)
      @piece3 = Pack::Piece.create(name: 'TS%0001 AC 201402 001',
                                   pack_id: @pack2.id,
                                   origin: 'scan',
                                   pre_assignment_state: 'processing')

      Timecop.return
    end

    it 'return 2 entries' do
      pre_assignments = PendingPreAssignmentService.pending(sort: 1)

      expect(pre_assignments.size).to eq(2)

      pre_assignment = pre_assignments.first
      expect(pre_assignment.date).to eq(@piece3.created_at)
      expect(pre_assignment.name).to eq('TS%0001 AC 201402')
      expect(pre_assignment.document_count).to eq(1)
      expect(pre_assignment.message).to be_nil

      pre_assignment = pre_assignments.last
      expect(pre_assignment.date).to eq(@piece1.created_at)
      expect(pre_assignment.name).to eq('TS%0001 AC 201401')
      expect(pre_assignment.document_count).to eq(2)
      expect(pre_assignment.message).to be_nil
    end
  end
end
