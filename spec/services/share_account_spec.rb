require 'spec_helper'

describe ShareAccount do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context 'given an organization, a customer, a collaborator and a contact' do
    before(:each) do
      @organization = create :organization, code: 'TS'

      @customer = create :user, code: 'TS%0001'
      @organization.members << @customer

      @collaborator = create :prescriber
      @organization.members << @collaborator
      @collaborator.extend_organization_role
      @collaborator

      @contact = create :guest
      @organization.members << @contact
    end
    context 'and given customer and collaborator are in the same group' do
      before(:each) do
        @group = Group.new
        @group.organization = @organization
        @group.name = 'Collaborateurs'
        @group.save
        @group.members << @collaborator
        @group.members << @customer
      end

      it "shares the customer's account to the contact" do
        params = { collaborator_id: @contact.id, account_id: @customer.id }

        expect(NotifyWorker).to receive(:perform_async).twice
        expect(DropboxImport).to receive(:changed)

        account_sharing = ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).to be_persisted
        expect(@contact.accounts).to eq [@customer]
        expect(Notification.count).to eq 2
        expect(@contact.notifications.size).to eq 1
        expect(@customer.notifications.size).to eq 1
      end

      it "shares the customer's account to another customer" do
        customer2 = create :user, code: 'TS%0002'
        @organization.members << customer2
        @group.members << customer2

        params = { collaborator_id: customer2.id, account_id: @customer.id }

        expect(NotifyWorker).to receive(:perform_async).twice
        expect(DropboxImport).to receive(:changed)

        account_sharing = ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).to be_persisted
        expect(customer2.accounts).to eq [@customer]
        expect(Notification.count).to eq 2
        expect(@customer.notifications.size).to eq 1
        expect(customer2.notifications.size).to eq 1
      end

      it "fails to share the customer's account because contact is not part of the same organization" do
        contact2 = create :guest
        params = { collaborator_id: contact2.id, account_id: @customer.id }

        expect(NotifyWorker).not_to receive(:perform_async)
        expect(DropboxImport).not_to receive(:changed)

        account_sharing = ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).not_to be_persisted
        expect(contact2.accounts).to be_empty
        expect(Notification.count).to eq 0
      end

      it "fails to share the customer's account because customer2 is not part of the same group as collaborator" do
        customer2 = create :user, code: 'TS%0002'
        @organization.members << customer2

        params = { collaborator_id: customer2.id, account_id: @customer.id }

        expect(NotifyWorker).not_to receive(:perform_async)
        expect(DropboxImport).not_to receive(:changed)

        account_sharing = ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).not_to be_persisted
        expect(customer2.accounts).to be_empty
        expect(Notification.count).to eq 0
      end
    end

    context 'given there is no group' do
      it "fails to share the customer's account" do
        params = { collaborator_id: @contact.id, account_id: @customer.id }

        expect(NotifyWorker).not_to receive(:perform_async)
        expect(DropboxImport).not_to receive(:changed)

        account_sharing = ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).not_to be_persisted
        expect(@contact.accounts).to be_empty
        expect(Notification.count).to eq 0
      end
    end
  end
end
