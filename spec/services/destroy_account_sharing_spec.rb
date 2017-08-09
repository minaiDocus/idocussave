require 'spec_helper'

describe DestroyAccountSharing do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context 'given an organization, a contact, a collaborator and a customer' do
    before(:each) do
      @organization = create(:organization)
      @collaborator = create(:prescriber)
      @contact      = create(:guest)
      @customer     = create(:user)

      @organization.members << @collaborator
      @organization.members << @contact
      @organization.members << @customer
    end

    context "given customer's account are already shared with contact" do
      before(:each) do
        @account_sharing = AccountSharing.new
        @account_sharing.organization  = @organization
        @account_sharing.authorized_by = @collaborator
        @account_sharing.collaborator  = @contact
        @account_sharing.account       = @customer
        @account_sharing.is_approved   = true
        @account_sharing.save
      end

      it "unshares customer's account from contact" do
        expect(NotifyWorker).to receive(:perform_async)
        expect(DropboxImport).to receive(:changed)

        DestroyAccountSharing.new(@account_sharing).execute

        expect(@account_sharing).to be_destroyed
        expect(@contact.accounts).to be_empty
        expect(Notification.count).to eq 1
        expect(@contact.notifications.first.title).to eq 'Accès à un compte révoqué'
      end
    end

    context "given an access request for the customer's account exist" do
      before(:each) do
        @account_sharing = AccountSharing.new
        @account_sharing.organization  = @organization
        @account_sharing.authorized_by = @collaborator
        @account_sharing.collaborator  = @contact
        @account_sharing.account       = @customer
        @account_sharing.is_approved   = false
        @account_sharing.save
      end

      it 'denies the request' do
        expect(NotifyWorker).to receive(:perform_async)
        expect(DropboxImport).to receive(:changed)

        DestroyAccountSharing.new(@account_sharing).execute

        expect(@account_sharing).to be_destroyed
        expect(@contact.accounts).to be_empty
        expect(Notification.count).to eq 1
        expect(@contact.notifications.first.title).to eq 'Accès à un compte refusé'
      end

      it 'cancels the request and notify the collaborator in charge of the account' do
        @customer.parent = @collaborator
        @customer.save

        expect(NotifyWorker).to receive(:perform_async)
        expect(DropboxImport).to receive(:changed)

        DestroyAccountSharing.new(@account_sharing, @contact).execute

        expect(@account_sharing).to be_destroyed
        expect(@contact.accounts).to be_empty
        expect(Notification.count).to eq 1
        expect(@collaborator.notifications.first.title).to eq "Demande d'accès à un compte annulé"
      end

      it 'cancels the request and notify the leader of the organization' do
        leader = create :prescriber
        @organization.members << leader
        @organization.leader = leader
        @organization.save

        expect(NotifyWorker).to receive(:perform_async)
        expect(DropboxImport).to receive(:changed)

        DestroyAccountSharing.new(@account_sharing, @contact).execute

        expect(@account_sharing).to be_destroyed
        expect(@contact.accounts).to be_empty
        expect(Notification.count).to eq 1
        expect(leader.notifications.first.title).to eq "Demande d'accès à un compte annulé"
      end

      it 'cancels the request and does not send a notification' do
        expect(NotifyWorker).not_to receive(:perform_async)
        expect(DropboxImport).to receive(:changed)

        DestroyAccountSharing.new(@account_sharing, @contact).execute

        expect(@account_sharing).to be_destroyed
        expect(@contact.accounts).to be_empty
        expect(Notification.count).to eq 0
      end
    end
  end
end
