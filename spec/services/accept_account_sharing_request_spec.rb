require 'spec_helper'

describe AcceptAccountSharingRequest do
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

      @collaborator = create :prescriber, code: 'TS%COL1'
      Member.create(user: @collaborator, organization: @organization, code: 'TS%COL1')

      @contact = create :guest
      @organization.guest_collaborators << @contact
    end

    context 'given a sharing request already exist' do
      before(:each) do
        request = AccountSharingRequest.new
        request.user = @contact
        request.code_or_email = 'TS%0001'
        request.save
      end

      it "accepts the sharing of customer's account to contact" do
        expect(Notifications::Notifier).to receive(:notify).twice
        expect(FileImport::Dropbox::Import).to receive(:changed)
        expect(@contact.accounts).to be_empty

        AcceptAccountSharingRequest.new(AccountSharing.unscoped.first).execute

        expect(@contact.accounts).to eq [@customer]
        expect(Notification.count).to eq 2
        expect(@contact.notifications.first.title).to eq "Demande d'accès à un dossier accepté"
        expect(@customer.notifications.first.title).to eq 'Partage de compte'
      end
    end
  end
end
