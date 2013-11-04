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
      @collaborator = FactoryGirl.create(:prescriber)
      @customer = FactoryGirl.create(:user)

      @organization = Organization.create name: 'iDocus', code: 'IDOC', leader_id: @collaborator.id
      @organization.members << @collaborator
      @organization.members << @customer

      @group = Group.create name: 'Group 1', organization_id: @organization.id
      @group.members << @collaborator
      @group.members << @customer
    end

    describe 'As an organization' do
      it 'should have collaborator' do
        @organization.collaborators.should include(@collaborator)
        @organization.collaborators.count.should eq(1)
        @organization.customers.should include(@customer)
        @organization.customers.count.should eq(1)
      end
    end

    describe 'As a group' do
      it 'should have collaborator' do
        @group.collaborators.should include(@collaborator)
        @group.collaborators.count.should eq(1)
        @group.customers.should include(@customer)
        @group.customers.count.should eq(1)
      end
    end

    describe 'As a collaborator' do
      it 'should be part of an organization and a group' do
        @collaborator.organization.should eq(@organization)
        @collaborator.groups.should include(@group)
        @collaborator.groups.count.should eq(1)
      end
    end

    describe 'As a customer' do
      it 'should be part of an organization and a group' do
        @customer.organization.should eq(@organization)
        @customer.groups.should include(@group)
        @customer.groups.count.should eq(1)
      end
    end
  end
end