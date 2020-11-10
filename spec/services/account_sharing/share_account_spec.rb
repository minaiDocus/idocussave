require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe AccountSharing::ShareAccount do
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
      @organization.customers << @customer

      user = create(:user, is_prescriber: true)
      @collaborator = Collaborator.new(user)
      @member = Member.create(user: user, organization: @organization, code: 'TS%COL1')

      @contact = create :user, is_guest: true
      @organization.guest_collaborators << @contact
    end

    context 'and given customer and collaborator are in the same group' do
      before(:each) do
        @group = Group.new
        @group.organization = @organization
        @group.name = 'Collaborateurs'
        @group.save
        @group.members << @member
        @group.customers << @customer
      end

      it "shares the customer's account to the contact" do
        params = { collaborator_id: @contact.id, account_id: @customer.id }

        expect(Notifications::Notifier).to receive(:notify).with(any_args).exactly(:twice)
        expect(FileImport::Dropbox).to receive(:changed)

        account_sharing = AccountSharing::ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).to be_persisted
        expect(@contact.accounts).to eq [@customer]
        expect(Notification.count).to eq 2
        expect(@contact.notifications.size).to eq 1
        expect(@customer.notifications.size).to eq 1
      end

      it "shares the customer's account to another customer" do
        customer2 = create :user, code: 'TS%0002'
        @organization.customers << customer2
        @group.customers << customer2

        params = { collaborator_id: customer2.id, account_id: @customer.id }

        expect(Notifications::Notifier).to receive(:notify).with(any_args).exactly(:twice)
        expect(FileImport::Dropbox).to receive(:changed)

        account_sharing = AccountSharing::ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).to be_persisted
        expect(customer2.accounts).to eq [@customer]
        expect(Notification.count).to eq 2
        expect(@customer.notifications.size).to eq 1
        expect(customer2.notifications.size).to eq 1
      end

      it "fails to share the customer's account because contact is not part of the same organization" do
        contact2 = create :user, is_guest: true
        params = { collaborator_id: contact2.id, account_id: @customer.id }

        expect(Notifications::Notifier).not_to receive(:notify)
        expect(FileImport::Dropbox).not_to receive(:changed)

        account_sharing = AccountSharing::ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).not_to be_persisted
        expect(contact2.accounts).to be_empty
        expect(Notification.count).to eq 0
      end

      it "fails to share the customer's account because customer2 is not part of the same group as collaborator" do
        customer2 = create :user, code: 'TS%0002'
        @organization.customers << customer2

        params = { collaborator_id: customer2.id, account_id: @customer.id }

        expect(Notifications::Notifier).not_to receive(:notify)
        expect(FileImport::Dropbox).not_to receive(:changed)

        account_sharing = AccountSharing::ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).not_to be_persisted
        expect(customer2.accounts).to be_empty
        expect(Notification.count).to eq 0
      end
    end

    context 'given there is no group' do
      it "fails to share the customer's account" do
        params = { collaborator_id: @contact.id, account_id: @customer.id }

        expect(Notifications::Notifier).not_to receive(:notify)
        expect(FileImport::Dropbox).not_to receive(:changed)

        account_sharing = AccountSharing::ShareAccount.new(@collaborator, params).execute

        expect(account_sharing).not_to be_persisted
        expect(@contact.accounts).to be_empty
        expect(Notification.count).to eq 0
      end
    end
  end
end
