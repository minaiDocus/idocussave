require 'spec_helper'

describe 'Organization Management' do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  describe 'relation' do
    before(:each) do
      @collaborator = FactoryBot.create(:prescriber)
      @customer = FactoryBot.create(:user)

      @organization = Organization.create name: 'iDocus', code: 'IDOC', leader_id: @collaborator.id
      @organization.customers << @customer
      @member = Member.create(user: @collaborator, organization: @organization, code: 'IDOC%COL1')

      @group = Group.create name: 'Group 1', organization_id: @organization.id
      @group.members << @member
      @group.customers << @customer
    end

    describe 'As an organization' do
      it 'should have collaborator' do
        expect(@organization.collaborators).to include(@collaborator)
        expect(@organization.collaborators.count).to eq(1)
        expect(@organization.customers).to include(@customer)
        expect(@organization.customers.count).to eq(1)
      end
    end

    describe 'As a group' do
      it 'should have collaborator' do
        expect(@group.collaborators).to include(@collaborator)
        expect(@group.collaborators.count).to eq(1)
        expect(@group.customers).to include(@customer)
        expect(@group.customers.count).to eq(1)
      end
    end

    describe 'As a collaborator (member)' do
      it 'should be part of an organization and a group' do
        expect(@member.organization).to eq(@organization)
        expect(@member.groups).to include(@group)
        expect(@member.groups.count).to eq(1)
      end
    end

    describe 'As a customer' do
      it 'should be part of an organization and a group' do
        expect(@customer.organization).to eq(@organization)
        expect(@customer.groups).to include(@group)
        expect(@customer.groups.count).to eq(1)
      end
    end
  end
end
