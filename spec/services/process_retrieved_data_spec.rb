# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe ProcessRetrievedData do
  before(:each) do
    @user = FactoryGirl.create(:user, code: 'IDO%0001')
    @user.options = UserOptions.create(user_id: @user.id)
    @journal = FactoryGirl.create :account_book_type, user_id: @user.id
    @retriever = Retriever.new
    @retriever.user         = @user
    @retriever.api_id       = 7
    @retriever.connector_id = 40
    @retriever.service_name = 'Connecteur de test'
    @retriever.type         = 'both'
    @retriever.name         = 'Connecteur de test'
    @retriever.journal      = @journal
    @retriever.state        = 'ready'
    @retriever.save
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context 'no preexisting bank account' do
    it 'does not create any bank account' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '0_bank_account.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 0
    end

    it 'creates a bank account and an operation' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 1
      expect(@user.operations.count).to eq 1
    end
  end

  context 'a bank account already exist' do
    before(:each) do
      @bank_account = BankAccount.new
      @bank_account.user      = @user
      @bank_account.retriever = @retriever
      @bank_account.api_id    = 17
      @bank_account.bank_name = @retriever.service_name
      @bank_account.name      = 'Compte chèque'
      @bank_account.number    = '3002900000'
      @bank_account.save
    end

    it 'does not create a new bank account, but an operation' do
      expect(@user.bank_accounts.count).to eq 1

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 1
      expect(@user.operations.count).to eq 1
    end

    it 'creates only one bank account, and 3 operations' do
      expect(@user.bank_accounts.count).to eq 1

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '2_bank_accounts.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 2
      expect(@user.operations.count).to eq 3
    end

    it 'destroys the bank account, but not the operation' do
      operation = Operation.new
      operation.user         = @user
      operation.bank_account = @bank_account
      operation.api_id       = 309
      operation.api_name     = 'budgea'
      operation.is_locked    = true
      operation.date         = '2015-06-18'
      operation.value_date   = '2015-06-17'
      operation.label        = "FACTURE CB HALL'S BEER"
      operation.amount       = -16.22
      operation.comment      = nil
      operation.type         = 'card'
      operation.category_id  = 9998
      operation.category     = 'Indéfini'
      operation.save

      expect(@user.bank_accounts.count).to eq 1
      expect(@user.operations.count).to eq 1

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'destroy_bank_account.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      operation.reload
      expect(@user.bank_accounts.count).to eq 0
      expect(operation.api_id).to be_nil
    end

    context 'an operation already exist' do
      before(:each) do
        @operation = Operation.new
        @operation.user         = @user
        @operation.bank_account = @bank_account
        @operation.api_id       = 309
        @operation.api_name     = 'budgea'
        @operation.is_locked    = true
        @operation.date         = '2015-06-18'
        @operation.value_date   = '2015-06-17'
        @operation.label        = "FACTURE CB HALL'S BEER"
        @operation.amount       = -16.22
        @operation.comment      = nil
        @operation.type         = 'card'
        @operation.category_id  = 9998
        @operation.category     = 'Indéfini'
        @operation.save
      end

      it 'updates the operation' do
        @operation.update(label: 'FACTURE CB')

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'bank_operation_update.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        @operation.reload
        expect(@user.operations.count).to eq 1
        expect(@operation.label).to eq("FACTURE CB HALL'S BEER")
      end

      it 'does not create a new operation' do
        expect(@user.operations.count).to eq 1

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        expect(@user.operations.count).to eq 1
      end

      it 'reattaches the operation to the bank account' do
        @operation.update(api_id: nil, bank_account_id: nil)

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        @operation.reload
        expect(@user.operations.count).to eq 1
        expect(@operation.api_id).to eq 309
        expect(@operation.bank_account).to eq @bank_account
      end
    end
  end

  it 'updates an old (fiduceo) bank account' do
    bank_account = BankAccount.new
    bank_account.user      = @user
    bank_account.retriever = @retriever
    bank_account.api_id    = '1234'
    bank_account.api_name  = 'fiduceo'
    bank_account.bank_name = @retriever.service_name
    bank_account.name      = 'Compte CH.'
    bank_account.number    = '3002900000'
    bank_account.save

    retrieved_data = RetrievedData.new
    retrieved_data.user = @user
    retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
    retrieved_data.save

    ProcessRetrievedData.new(retrieved_data).execute

    bank_account.reload
    expect(bank_account.api_id).to eq 17
    expect(bank_account.api_name).to eq 'budgea'
    expect(bank_account.name).to eq 'Compte chèque'
  end

  context 'no preexisting document' do
    before(:each) do
      budgea_account = BudgeaAccount.new
      budgea_account.user = @user
      budgea_account.identifier = 7
      budgea_account.access_token = "rj3SxgMSyueBl1UVjXvWBH2gaRr/CMMl"
      budgea_account.save
    end

    it 'does not create any document' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '0_document.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(retrieved_data).to be_processed
      expect(retrieved_data.processed_connection_ids).to eq [7]
      expect(@retriever).to be_ready
      expect(@user.temp_documents.count).to eq 0
    end

    it 'creates a document' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
      retrieved_data.save

      VCR.use_cassette('budgea/get_document') do
        ProcessRetrievedData.new(retrieved_data).execute
      end

      @retriever.reload
      expect(retrieved_data).to be_processed
      expect(retrieved_data.processed_connection_ids).to eq [7]
      expect(@retriever).to be_waiting_selection
      expect(@user.temp_documents.count).to eq 1
    end

    it 'fails to fetch document' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
      retrieved_data.save

      VCR.use_cassette('budgea/failed_to_fetch_document') do
        ProcessRetrievedData.new(retrieved_data).execute
      end

      @retriever.reload
      expect(@user.temp_documents.count).to eq 0
      expect(retrieved_data).to be_error
      expect(retrieved_data.error_message).to eq "[7] Document '15' cannot be downloaded : [0] "
      expect(retrieved_data.processed_connection_ids).to be_empty
      expect(@retriever).to be_error
      expect(@retriever.error_message).to eq "Certains documents n'ont pas pu être récupérés."
    end
  end

  context 'a document already exist' do
    before(:each) do
      budgea_account = BudgeaAccount.new
      budgea_account.user = @user
      budgea_account.identifier = 7
      budgea_account.access_token = "rj3SxgMSyueBl1UVjXvWBH2gaRr/CMMl"
      budgea_account.save

      pack = TempPack.find_or_create_by_name "#{@user.code} #{@journal.name} #{Time.now.strftime('%Y%M')}"
      options = {
        user_id:               @user.id,
        delivery_type:         'retriever',
        api_id:                15,
        api_name:              'budgea',
        is_content_file_valid: true
      }
      file = File.open(Rails.root.join('spec', 'support', 'files', '2pages.pdf'), 'r')
      temp_document = pack.add file, options
      @retriever.temp_documents << temp_document
      file.close
    end

    it 'does not create a document' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
      retrieved_data.save

      expect(@user.temp_documents.count).to eq 1

      VCR.use_cassette('budgea/get_document') do
        ProcessRetrievedData.new(retrieved_data).execute
      end

      @retriever.reload
      expect(retrieved_data).to be_processed
      expect(retrieved_data.processed_connection_ids).to eq [7]
      expect(@retriever).to be_ready
      expect(@user.temp_documents.count).to eq 1
    end
  end

  context 'retriever state is ready' do
    it 'changes state to error' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'wrong_password.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_error
      expect(@retriever.error_message).to eq "Mot de passe incorrecte."
      expect(@retriever.is_new_password_needed).to be true
    end

    it 'changes state to waiting_additionnal_info' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'waiting_additionnal_info.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_waiting_additionnal_info
      expect(@retriever.error_message).to be_nil
    end
  end

  context 'retriever state is error' do
    before(:each) do
      @retriever.error
      @retriever.update(error_message: 'something')
    end

    it 'changes state to ready' do
      @retriever.update(is_selection_needed: false)

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_ready
      expect(@retriever.error_message).to be_nil
    end
  end
end
