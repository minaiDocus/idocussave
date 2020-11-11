# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreAssignment::Pending do
  describe '.unresolved' do
    before(:all) do
      organization = FactoryBot.create :organization, code: 'IDO'
      user  = FactoryBot.create :user,  code: 'IDO%001', organization: organization

      Timecop.freeze(Time.local(2020,1,1,8,0,0))
      pack = Pack.create(name: 'IDO%001 AC 202001 all', owner_id: user.id, organization: organization)
      @piece1 = Pack::Piece.create(name: 'IDO%001 AC 202001 001',
                                   pack_id: pack.id,
                                   user: user,
                                   organization: organization,
                                   origin: 'scan',
                                   is_awaiting_pre_assignment: true)
      @piece2 = Pack::Piece.create(name: 'IDO%001 AC 202001 002',
                                   pack_id: pack.id,
                                   user: user,
                                   organization: organization,
                                   origin: 'scan',
                                   is_awaiting_pre_assignment: true)

      Timecop.freeze(Time.local(2020,2,1,8,0,0))
      pack2 = Pack.create(name: 'IDO%001 AC 202002 all', owner_id: user.id, organization: organization)
      @piece3 = Pack::Piece.create(name: 'IDO%001 AC 202002 001',
                                   pack_id: pack2.id,
                                   user: user,
                                   organization: organization,
                                   origin: 'scan',
                                   is_awaiting_pre_assignment: true)

      Timecop.return
    end

    it 'return 2 entries' do
      pre_assignments = PreAssignment::Pending.unresolved(sort: 1)

      expect(pre_assignments.size).to eq(2)

      pre_assignment = pre_assignments.first
      expect(pre_assignment.date).to eq(@piece3.created_at)
      expect(pre_assignment.name).to eq('IDO%001 AC 202002')
      expect(pre_assignment.document_count).to eq(1)
      expect(pre_assignment.message).to be_nil

      pre_assignment = pre_assignments.last
      expect(pre_assignment.date).to eq(@piece1.created_at)
      expect(pre_assignment.name).to eq('IDO%001 AC 202001')
      expect(pre_assignment.document_count).to eq(2)
      expect(pre_assignment.message).to be_nil
    end
  end
end
