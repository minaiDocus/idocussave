require 'spec_helper'

describe AccountSharingRequest do
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

      @collaborator = create :prescriber
      @member = Member.create(user: @collaborator, organization: @organization, code: 'TS%COL1')

      @contact = create :guest
      @organization.guest_collaborators << @contact
    end

    it "contact requests an access to customer's account" do
      request = AccountSharingRequest.new
      request.user = @contact
      request.code_or_email = 'TS%0001'

      expect(request.save).to eq true
      pending_account_sharing = @contact.account_sharings.unscoped.pending.first
      expect(pending_account_sharing.account).to eq @customer
    end

    it "another customer requests an access to the customer's account" do
      customer2 = create :user, code: 'TS%0002'
      @organization.customers << customer2

      request = AccountSharingRequest.new
      request.user = customer2
      request.code_or_email = 'TS%0001'

      expect(request.save).to eq true
      pending_account_sharing = customer2.account_sharings.unscoped.pending.first
      expect(pending_account_sharing.account).to eq @customer
    end

    it 'notifies the collaborator in charge of the account' do
      @customer.update(manager: @member)

      request = AccountSharingRequest.new
      request.user = @contact
      request.code_or_email = 'TS%0001'

      expect(Notifications::Notifier).to receive(:notify)

      request.save

      expect(@collaborator.notifications.size).to eq 1
      expect(@collaborator.notifications.first.title).to eq "Demande d'accès à un dossier"
    end

    it 'notifies the administrator of the organization' do
      leader = create :prescriber
      Member.create(user: leader, organization: @organization, code: 'TS%LEAD', role: Member::ADMIN)

      request = AccountSharingRequest.new
      request.user = @contact
      request.code_or_email = 'TS%0001'

      expect(Notifications::Notifier).to receive(:notify)

      request.save

      expect(leader.notifications.size).to eq 1
      expect(leader.notifications.first.title).to eq "Demande d'accès à un dossier"
    end

    context "given the customer's account is already requested to share" do
      before(:each) do
        request = AccountSharingRequest.new
        request.user = @contact
        request.code_or_email = 'TS%0001'
        request.save
      end

      it "cannot request to share again" do
        request = AccountSharingRequest.new
        request.user = @contact
        request.code_or_email = 'TS%0001'
        request.save

        expect(request.save).to eq false
        expect(request.errors.messages).to eq({ code_or_email: ["existe déjà"] })
      end
    end

    context "given the customer's account is already shared" do
      before(:each) do
        account_sharing = AccountSharing.new
        account_sharing.organization  = @organization
        account_sharing.authorized_by = @collaborator
        account_sharing.collaborator  = @contact
        account_sharing.account       = @customer
        account_sharing.save
      end

      it "cannot request to share again" do
        request = AccountSharingRequest.new
        request.user = @contact
        request.code_or_email = 'TS%0001'
        request.save

        expect(request.save).to eq false
        expect(request.errors.messages).to eq({ code_or_email: ["existe déjà"] })
      end
    end

    it 'fails to request a sharing' do
      request = AccountSharingRequest.new
      request.user = @contact
      request.code_or_email = '123'
      request.save

      expect(request.save).to eq false
      expect(request.errors.messages).to eq({ code_or_email: ["n'est pas valide"] })
    end

    it 'cannot request a sharing to someone on another organization' do
      organization2 = create :organization, code: 'ABC'
      customer3 = create :user, code: 'ABC%0001'
      organization2.customers << customer3

      request = AccountSharingRequest.new
      request.user = @contact
      request.code_or_email = 'ABC%0001'
      request.save

      expect(request.save).to eq false
      expect(request.errors.messages).to eq({ code_or_email: ["n'est pas valide"] })
    end

    it 'cannot request a sharing to a user different than a customer' do
      request = AccountSharingRequest.new
      request.user = @contact
      request.code_or_email = 'TS%COL1'
      request.save

      expect(request.save).to eq false
      expect(request.errors.messages).to eq({ code_or_email: ["n'est pas valide"] })
    end
  end
end
