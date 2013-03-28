require 'spec_helper'

describe "Journal's request system" do
  before(:each) do
    @prescriber = FactoryGirl.create(:prescriber)
    @organization = FactoryGirl.create(:organization, leader_id: @prescriber.id)
    @organization.members << @prescriber

    @customer = FactoryGirl.create(:user)
    @organization.members << @customer

    @journal = FactoryGirl.create(:account_book_type, organization_id: @organization.id)
  end

  it 'should create request after creation' do
    @journal.request.class.should eq(Request)
  end

  it 'should request update successfully' do
    @journal.request.set_attributes({ 'name' => 'TEST' })
    @journal.request.action.should eq('update')
  end

  it 'should not request successfully' do
    @journal.request.set_attributes({ 'name' => @journal.name })
    @journal.request.action.should eq('')
  end

  context 'relation update' do
    before(:each) do
      @journal.requested_clients << @customer
      @journal.update_request_status!([@customer])
    end

    it 'should set relation_action to "update" successfully' do
      @journal.request.relation_action.should eq('update')
    end

    it 'should set relation_action to "update" on customer successfully' do
      @customer.request.relation_action.should eq('update')
    end

    context 'accepted' do
      before(:each) do
        @journal.clients << @customer
        @journal.update_request_status!([@customer])
      end

      it 'should defaulted relation_action successfully' do
        @journal.request.relation_action.should eq('')
      end

      it 'should update relation successfully' do
        @journal.clients.should eq(@journal.requested_clients)
      end

      it 'should defaulted relation_action on customer successfully' do
        @customer.request.relation_action.should eq('')
      end

      it 'should update relation on customer successfully' do
        @customer.account_book_types.should eq(@customer.requested_account_book_types)
      end
    end

    context 'rejected' do
      before(:each) do
        @journal.update_attribute('requested_client_ids', [])
        @customer.reload
        @journal.update_request_status!([@customer])
      end

      it 'should defaulted relation_action successfully' do
        @journal.request.relation_action.should eq('')
      end

      it 'should defaulted relation_action on customer successfully' do
        @customer.request.relation_action.should eq('')
      end
    end
  end
end