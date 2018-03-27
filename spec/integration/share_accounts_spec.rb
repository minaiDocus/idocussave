require 'spec_helper'

describe 'Share accounts' do
  before(:each) do
    DatabaseCleaner.start

    @organization       = create(:organization)
    @collaborator       = create(:prescriber)
    @guest_collaborator = create(:guest)
    @user               = create(:user)

    Member.create(user: @user, organization: @organization, code: 'TS%COL1')
    @organization.guest_collaborators << @guest_collaborator
    @organization.customers << @user
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it 'shares an account successfully' do
    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator
    account_sharing.account       = @user

    expect(account_sharing.save).to be true
    expect(@guest_collaborator.accounts).to eq [@user]
    expect(@user.collaborators).to eq [@guest_collaborator]
    expect(@collaborator.authorized_account_sharings).to eq [account_sharing]
  end

  it 'cannot share his account to himself' do
    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator
    account_sharing.account       = @guest_collaborator

    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ collaborator_id: ["n'est pas valide"], account_id: ["n'est pas valide"] })
  end

  it 'collaborator should be a guest or a customer' do
    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.account       = @user

    account_sharing.collaborator = @collaborator
    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ collaborator_id: ["n'est pas valide"] })

    admin = create(:admin)
    Member.create(user: admin, organization: @organization, code: 'TS%ADM')
    account_sharing.collaborator = admin
    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ collaborator_id: ["n'est pas valide"] })

    user = create(:user)
    @organization.customers << user
    account_sharing.collaborator = user
    expect(account_sharing.save).to be true
  end

  it 'account should be a customer' do
    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator

    account_sharing.account = @collaborator
    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ account_id: ["n'est pas valide"] })

    guest_collaborator = create(:guest)
    @organization.guest_collaborators << guest_collaborator
    account_sharing.account = guest_collaborator
    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ account_id: ["n'est pas valide"] })

    admin = create(:admin)
    Member.create(user: admin, organization: @organization, code: 'TS%ADM')
    account_sharing.account = admin
    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ account_id: ["n'est pas valide"] })
  end

  it 'guest_collaborator should belongs to the same organization' do
    organization2 = create(:organization)
    organization2.guest_collaborators << @guest_collaborator

    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator
    account_sharing.account       = @user

    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ collaborator_id: ["n'est pas valide"] })
  end

  it 'account should belongs to the same organization' do
    organization2 = create(:organization)
    organization2.customers << @user

    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator
    account_sharing.account       = @user

    expect(account_sharing.save).to be false
    expect(account_sharing.errors.messages).to eq({ account_id: ["n'est pas valide"] })
  end

  context 'given an account are shared with a guest collaborator' do
    before(:each) do
      @account_sharing = AccountSharing.new
      @account_sharing.organization  = @organization
      @account_sharing.authorized_by = @collaborator
      @account_sharing.collaborator  = @guest_collaborator
      @account_sharing.account       = @user
      @account_sharing.save
    end

    it 'unshares the account successfully' do
      @account_sharing.destroy

      expect(@guest_collaborator.accounts.size).to eq 0
      expect(@user.collaborators.size).to eq 0
    end
  end

  it 'fails on duplicate' do
    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator
    account_sharing.account       = @user
    expect(account_sharing.save).to be true

    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator
    account_sharing.account       = @user
    expect(account_sharing.save).to be false
  end

  it 'updates successfully' do
    account_sharing = AccountSharing.new
    account_sharing.organization  = @organization
    account_sharing.authorized_by = @collaborator
    account_sharing.collaborator  = @guest_collaborator
    account_sharing.account       = @user
    expect(account_sharing.save).to be true

    account_sharing.is_approved   = true
    expect(account_sharing.save).to be true
  end

  context 'search' do
    before(:each) do
      @guest_collaborator2 = create(:guest)
      @organization.guest_collaborators << @guest_collaborator2

      @guest_collaborator.company    = 'COMP4'
      @guest_collaborator.first_name = 'Paul'
      @guest_collaborator.last_name  = 'Du bois'
      @guest_collaborator.save

      @guest_collaborator2.company    = 'COMP5'
      @guest_collaborator2.first_name = 'Maria'
      @guest_collaborator2.last_name  = 'Fisher'
      @guest_collaborator2.save

      @user2 = create(:user)
      @organization.customers << @user2

      @user3 = create(:user)
      @organization.customers << @user3

      @user.company    = 'COMP1'
      @user.first_name = 'John'
      @user.last_name  = 'Doe'
      @user.save

      @user2.company    = 'COMP2'
      @user2.first_name = 'Alice'
      @user2.last_name  = 'Du Pond'
      @user2.save

      @user3.company    = 'COMP3'
      @user3.first_name = 'Ricky'
      @user3.last_name  = 'Martin'
      @user3.save

      @account_sharing = AccountSharing.new
      @account_sharing.organization  = @organization
      @account_sharing.authorized_by = @collaborator
      @account_sharing.collaborator  = @guest_collaborator
      @account_sharing.account       = @user
      @account_sharing.save

      @account_sharing2 = AccountSharing.new
      @account_sharing2.organization  = @organization
      @account_sharing2.authorized_by = @collaborator
      @account_sharing2.collaborator  = @guest_collaborator
      @account_sharing2.account       = @user2
      @account_sharing2.save

      @account_sharing3 = AccountSharing.new
      @account_sharing3.organization  = @organization
      @account_sharing3.authorized_by = @collaborator
      @account_sharing3.collaborator  = @guest_collaborator2
      @account_sharing3.account       = @user3
      @account_sharing3.save
    end

    it "finds a sharing by an account's code" do
      result = AccountSharing.search(account: @user.code)

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing
    end

    it "finds a sharing by an account's company" do
      result = AccountSharing.search(account: 'COMP1')

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing
    end

    it "finds a sharing by an account's first name" do
      result = AccountSharing.search(account: 'Alice')

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing2
    end

    it "finds a sharing by an account's last name" do
      result = AccountSharing.search(account: 'DU POND')

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing2
    end

    it "finds a sharing by an account's full name" do
      result = AccountSharing.search(account: 'Alice DU POND')

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing2
    end

    it "finds a sharing by a guest collaborator's email" do
      result = AccountSharing.search(collaborator: @guest_collaborator2.email)

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing3
    end

    it "finds a sharing by a guest collaborator's code" do
      result = AccountSharing.search(collaborator: @guest_collaborator2.code)

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing3
    end

    it "finds a sharing by a guest collaborator's company" do
      result = AccountSharing.search(collaborator: 'COMP5')

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing3
    end

    it "finds a sharing by a guest collaborator's first name" do
      result = AccountSharing.search(collaborator: 'Maria')

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing3
    end

    it "finds a sharing by a guest collaborator's last name" do
      result = AccountSharing.search(collaborator: 'FISHER')

      expect(result.size).to eq 1
      expect(result.first).to eq @account_sharing3
    end

    context 'scoped' do
      before(:each) do
        @account_sharings = AccountSharing.where(account_id: [@user3.id])
      end

      it 'returns 1 result' do
        result = @account_sharings.search(account: 'COMP')

        expect(result.size).to eq 1
      end

      it 'returns 0 result' do
        result = @account_sharings.search(account: 'John')

        expect(result.size).to eq 0
      end
    end
  end
end
