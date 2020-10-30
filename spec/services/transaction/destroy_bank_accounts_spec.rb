require 'spec_helper'

describe Transaction::DestroyBankAccounts do
  before(:each) do
    DatabaseCleaner.start
    @organization = FactoryBot.create :organization, code: 'IDO'
    @user         = FactoryBot.create :user, code: 'IDO%0001', organization: @organization
    @user.options = UserOptions.create(user_id: @user.id)
    @journal      = FactoryBot.create :account_book_type, user_id: @user.id
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context 'given a retriever has 2 bank accounts and 2 operations' do
    before(:each) do
      @retriever = Retriever.new
      @retriever.user         = @user
      @retriever.journal      = @journal
      @retriever.budgea_id    = 8
      @retriever.name         = 'Connecteur de test'
      @retriever.service_name = 'Connecteur de test'
      @retriever.state        = 'ready'
      @retriever.budgea_state = 'successful'
      @retriever.save

      @bank_account = BankAccount.new
      @bank_account.user      = @user
      @bank_account.retriever = @retriever
      @bank_account.api_id    = 5
      @bank_account.bank_name = @retriever.service_name
      @bank_account.name      = 'Compte chèque'
      @bank_account.number    = '3002900000'
      @bank_account.save

      @bank_account2 = BankAccount.new
      @bank_account2.user      = @user
      @bank_account2.retriever = @retriever
      @bank_account2.api_id    = 6
      @bank_account2.bank_name = @retriever.service_name
      @bank_account2.name      = 'Compte carte'
      @bank_account2.number    = '200070500'
      @bank_account2.save

      @operation = Operation.new
      @operation.user         = @user
      @operation.organization = @organization
      @operation.bank_account = @bank_account
      @operation.api_id       = 504
      @operation.api_name     = 'budgea'
      @operation.is_locked    = true
      @operation.date         = '2017-01-18'
      @operation.value_date   = '2017-01-18'
      @operation.label        = "FACTURE CB RESTO Le Bois"
      @operation.amount       = -20.56
      @operation.comment      = nil
      @operation.type_name    = 'card'
      @operation.category_id  = 9998
      @operation.category     = 'Indéfini'
      @operation.save

      @operation2 = Operation.new
      @operation2.user         = @user
      @operation2.organization = @organization
      @operation2.bank_account = @bank_account
      @operation2.api_id       = 505
      @operation2.api_name     = 'budgea'
      @operation2.is_locked    = true
      @operation2.date         = '2017-01-18'
      @operation2.value_date   = '2017-01-18'
      @operation2.label        = "FACTURE CB PAYPAL 12.5€"
      @operation2.amount       = -12.5
      @operation2.comment      = nil
      @operation2.type_name    = 'card'
      @operation2.category_id  = 9998
      @operation2.category     = 'Indéfini'
      @operation2.save
    end

    context 'retriever has been destroyed' do
      before(:each) do
        @retriever.destroy

        @bank_account.reload
        @bank_account2.reload

        Transaction::DestroyBankAccounts.new([@bank_account, @bank_account2]).execute

        @operation.reload
        @operation2.reload
      end

      it 'destroys all bank accounts attached to the retriever' do
        expect(@user.bank_accounts.size).to eq 0
      end

      it 'nullify the bank_account_id of all attached operations' do
        expect(@operation.bank_account_id).to be_nil
        expect(@operation2.bank_account_id).to be_nil
      end
    end

    context 'retriever still exists' do
      it 'does nothing' do
        @bank_account.reload
        @bank_account2.reload

        Transaction::DestroyBankAccounts.new([@bank_account, @bank_account2]).execute

        @operation.reload
        @operation2.reload

        expect(@user.bank_accounts.size).to eq 2
        expect(@operation.bank_account).to be_present
        expect(@operation2.bank_account).to be_present
      end
    end
  end
end
