require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe AccountSharing::ShareMyAccount do
  before(:each) do
    DatabaseCleaner.start

    @organization = create :organization, code: 'TS'
    @user = create :user, code: 'TS%0001'
    @organization.customers << @user
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it 'shares his account to a new user successfully' do
    params = {
      email:      'john.doe@test.com',
      company:    'TEST',
      first_name: 'John',
      last_name:  'Doe'
    }

    expect(Notifications::Notifier).to receive(:notify)
    expect(FileImport::Dropbox).to receive(:changed)

    collaborator, account_sharing = AccountSharing::ShareMyAccount.new(@user, params, @user).execute

    expect(collaborator).to be_persisted
    expect(account_sharing).to be_persisted
    expect(collaborator).not_to eq @user
    expect(collaborator.accounts).to eq [@user]
    expect(collaborator.notifications.size).to eq 1
  end

  it 'fails to share his account' do
    params = { email: 'john.doe@test.com' }

    expect(Notifications::Notifier).not_to receive(:notify)
    expect(FileImport::Dropbox).not_to receive(:changed)

    collaborator, account_sharing = AccountSharing::ShareMyAccount.new(@user, params, @user).execute

    expect(collaborator).not_to be_persisted
    expect(account_sharing).not_to be_persisted
    expect(collaborator.errors.messages).to eq({ company: ['est vide'] })
    expect(collaborator.accounts).to be_empty
    expect(collaborator.notifications.size).to eq 0
  end

  it 'shares his account to another customer successfully' do
    user2 = create :user, code: 'TS%0002', email: 'test2@test.com'
    @organization.customers << user2
    params = { email: 'test2@test.com' }

    expect(Notifications::Notifier).to receive(:notify)
    expect(FileImport::Dropbox).to receive(:changed)

    collaborator, account_sharing = AccountSharing::ShareMyAccount.new(@user, params, @user).execute

    expect(collaborator).to eq user2
    expect(account_sharing).to be_persisted
    expect(user2.accounts).to eq [@user]
    expect(user2.notifications.size).to eq 1
  end

  it 'cannot share to a user of another organization' do
    user2 = create :user, code: 'TS%0002', email: 'test2@test.com'
    organization = create :organization
    organization.customers << user2
    params = { email: 'test2@test.com' }

    expect(Notifications::Notifier).not_to receive(:notify)
    expect(FileImport::Dropbox).not_to receive(:changed)

    collaborator, account_sharing = AccountSharing::ShareMyAccount.new(@user, params, @user).execute

    expect(collaborator).to eq user2
    expect(account_sharing).not_to be_persisted
    expect(collaborator.accounts).to eq []
    expect(account_sharing.errors[:collaborator_id]).to include("n'est pas valide")
    expect(collaborator.notifications.size).to eq 0
  end

  it 'cannot share to a collaborator' do
    user2 = create :user, is_prescriber: true, email: 'col@test.com'
    Member.create(user: user2, organization: @organization, code: 'TS%COL1')
    params = { email: 'col@test.com' }

    expect(Notifications::Notifier).not_to receive(:notify)
    expect(FileImport::Dropbox).not_to receive(:changed)

    collaborator, account_sharing = AccountSharing::ShareMyAccount.new(@user, params, @user).execute

    expect(account_sharing).not_to be_persisted
    expect(user2.accounts).to eq []
    expect(collaborator.errors[:email]).to include("est déjà pris.")
    expect(collaborator.notifications.size).to eq 0
  end

  context 'given a contact already exist' do
    before(:each) do
      @contact = create :user, is_guest: true, code: 'TS%SHR1', email: 'john.doe@test.com'
      @organization.guest_collaborators << @contact
    end

    it 'shares his account to the existing contact successfully' do
      params = { email: 'john.doe@test.com' }

      expect(Notifications::Notifier).to receive(:notify)
      expect(FileImport::Dropbox).to receive(:changed)

      collaborator, account_sharing = AccountSharing::ShareMyAccount.new(@user, params, @user).execute

      expect(collaborator).to be_valid
      expect(collaborator).to eq @contact
      expect(account_sharing).to be_persisted
      expect(collaborator.accounts).to eq [@user]
      expect(collaborator.notifications.size).to eq 1
    end

    context 'given his account is already shared' do
      before(:each) do
        account_sharing = AccountSharing.new
        account_sharing.organization  = @user.organization
        account_sharing.collaborator  = @contact
        account_sharing.account       = @user
        account_sharing.authorized_by = @user
        account_sharing.is_approved   = true
        account_sharing.save
      end

      it 'does not allow duplication' do
        params = { email: 'john.doe@test.com' }

        collaborator, account_sharing = AccountSharing::ShareMyAccount.new(@user, params, @user).execute

        expect(collaborator).to be_persisted
        expect(account_sharing).not_to be_persisted
        expect(Array(account_sharing.errors[:account] || account_sharing.errors[:collaborator])).to include("est déjà pris.")
      end
    end
  end
end
