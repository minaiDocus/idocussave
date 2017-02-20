# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe ProcessRetrievedData do
  before(:each) do
    @user = FactoryGirl.create(:user, code: 'IDO%0001')
    @user.options = UserOptions.create(user_id: @user.id)
    @journal = FactoryGirl.create :account_book_type, user_id: @user.id
    @connector = Connector.new
    @connector.name            = 'Connecteur de test'
    @connector.capabilities    = ['document', 'bank']
    @connector.apis            = ['budgea']
    @connector.active_apis     = ['budgea']
    @connector.budgea_id       = 40
    @connector.fiduceo_ref     = nil
    @connector.combined_fields = {
      login: {
        label:        'Identifiant',
        type:         'text',
        regex:        nil,
        budgea_name:  'login'
      },
      password: {
        label:        'Mot de passe',
        type:         'password',
        regex:        nil,
        budgea_name:  'password'
      }
    }
    @connector.save
    @retriever = Retriever.new
    @retriever.user           = @user
    @retriever.budgea_id      = 7
    @retriever.connector      = @connector
    @retriever.name           = 'Connecteur de test'
    @retriever.journal        = @journal
    @retriever.state          = 'ready'
    @retriever.budgea_state   = 'successful'
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
      operation.type_name    = 'card'
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
        @operation.type_name    = 'card'
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
        expect(@operation.api_id).to eq '309'
        expect(@operation.bank_account).to eq @bank_account
      end
    end
  end

  context '2 bank accounts already exist' do
    before(:each) do
      @bank_account = BankAccount.new
      @bank_account.user      = @user
      @bank_account.retriever = @retriever
      @bank_account.api_id    = 1
      @bank_account.bank_name = @retriever.service_name
      @bank_account.name      = 'Compte courant'
      @bank_account.number    = '3002900000'
      @bank_account.type_name = 'checking'
      @bank_account.save

      @bank_account2 = BankAccount.new
      @bank_account2.user      = @user
      @bank_account2.retriever = @retriever
      @bank_account2.api_id    = 2
      @bank_account2.bank_name = @retriever.service_name
      @bank_account2.name      = 'Carte Gold 1234XXXXXXXXXXXX'
      @bank_account2.number    = '2100005401'
      @bank_account2.type_name = 'card'
      @bank_account2.save
    end

    it 'creates 3 operations' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '2_bank_accounts_and_3_operations.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      expect(@user.operations.count).to eq 3

      @operation, @operation2, @operation3 = @user.operations.to_a

      expect(@operation.api_id).to eq '1'
      expect(@operation.label).to eq 'DAB 100€'

      # should detect '[CB] ...' here
      expect(@operation2.api_id).to eq '3'
      expect(@operation2.label).to eq '[CB] RESTO 33.5€'

      expect(@operation3.api_id).to eq '2'
      expect(@operation3.label).to eq 'Paypal 7.58€'
    end

    context '3 operations already exist' do
      before(:each) do
        @operation = Operation.new
        @operation.user         = @user
        @operation.api_name     = 'budgea'
        @operation.is_locked    = true
        @operation.date         = '2017-01-01'
        @operation.value_date   = '2017-01-01'
        @operation.label        = 'DAB 100€'
        @operation.amount       = -100.0
        @operation.type_name    = 'withdrawal'
        @operation.category_id  = 9998
        @operation.category     = 'Indéfini'
        @operation.save

        @operation2 = Operation.new
        @operation2.user         = @user
        @operation2.api_name     = 'budgea'
        @operation2.is_locked    = true
        @operation2.date         = '2017-01-02'
        @operation2.value_date   = '2017-01-02'
        @operation2.label        = 'Paypal 7.58€'
        @operation2.amount       = -7.58
        @operation2.type_name    = 'deferred_card'
        @operation2.category_id  = 9998
        @operation2.category     = 'Indéfini'
        @operation2.save

        @operation3 = Operation.new
        @operation3.user         = @user
        @operation3.api_name     = 'budgea'
        @operation3.is_locked    = true
        @operation3.date         = '2017-01-03'
        @operation3.value_date   = '2017-01-03'
        @operation3.label        = '[CB] RESTO 33.5€'
        @operation3.amount       = -33.5
        @operation3.comment      = nil
        @operation3.type_name    = 'deferred_card'
        @operation3.category_id  = 9998
        @operation3.category     = 'Indéfini'
        @operation3.save
      end

      it 'reattaches 3 operations to 2 bank accounts' do
        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '2_bank_accounts_and_3_operations.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        @operation.reload
        @operation2.reload
        @operation3.reload

        expect(@user.operations.count).to eq 3

        expect(@operation.api_id).to eq '1'
        expect(@operation.bank_account).to eq @bank_account

        expect(@operation2.api_id).to eq '2'
        expect(@operation2.bank_account).to eq @bank_account2

        # should detect '[CB] ...' here
        expect(@operation3.api_id).to eq '3'
        expect(@operation3.bank_account).to eq @bank_account
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
    expect(bank_account.api_id).to eq '17'
    expect(bank_account.api_name).to eq 'budgea'
    expect(bank_account.name).to eq 'Compte chèque'
  end

  context 'a configured and used bank account exists' do
    before(:each) do
      @bank_account = BankAccount.new
      @bank_account.user              = @user
      @bank_account.retriever         = @retriever
      @bank_account.api_id            = 4
      @bank_account.bank_name         = @retriever.service_name
      @bank_account.name              = 'Compte courant'
      @bank_account.number            = '2002700001'
      @bank_account.journal           = 'AC'
      @bank_account.accounting_number = 512000
      @bank_account.start_date        = Time.local(2016,12,1).to_date
      @bank_account.is_used           = true
      @bank_account.save
    end

    it 'creates 3 operations with different states' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '3_operations.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      expect(@user.operations.count).to eq 3

      operation1 = @user.operations[0]
      operation2 = @user.operations[1]
      operation3 = @user.operations[2]

      expect(operation1.label).to eq 'PRLV FREE'
      expect(operation1.is_locked).to eq true
      expect(operation1.is_coming).to eq false

      expect(operation2.label).to eq '[CB] FACTURE CB RESTO'
      expect(operation2.is_locked).to eq true
      expect(operation2.is_coming).to eq true

      expect(operation3.label).to eq 'Retrait DAB 100'
      expect(operation3.is_locked).to eq false
      expect(operation3.is_coming).to eq false
    end

    it 'updates 1 operation' do
      operation = Operation.new
      operation.organization = @user.organization
      operation.user         = @user
      operation.bank_account = @bank_account
      operation.api_id       = 2
      operation.api_name     = 'budgea'
      operation.date         = '2017-01-31'
      operation.value_date   = '2017-01-31'
      operation.label        = 'FACTURE CB RESTO'
      operation.amount       = -15.49
      operation.type_name    = 'cb_differed'
      operation.is_locked    = true
      operation.is_coming    = true
      operation.save

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'update_1_operation.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      operation = @user.operations.first

      expect(operation.label).to eq 'FACTURE CB RESTO Le Bois'
      expect(operation.is_locked).to eq true
      expect(operation.is_coming).to eq true
    end

    it 'unlocks 1 operation' do
      operation = Operation.new
      operation.organization = @user.organization
      operation.user         = @user
      operation.bank_account = @bank_account
      operation.api_id       = 2
      operation.api_name     = 'budgea'
      operation.date         = '2017-01-31'
      operation.value_date   = '2017-01-31'
      operation.label        = 'FACTURE CB RESTO'
      operation.amount       = -15.49
      operation.type_name    = 'cb_differed'
      operation.is_locked    = true
      operation.is_coming    = true
      operation.save

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'unlock_1_operation.json')))
      retrieved_data.save

      ProcessRetrievedData.new(retrieved_data).execute

      operation = @user.operations.first

      expect(operation.label).to eq 'FACTURE CB RESTO Le Bois'
      expect(operation.is_locked).to eq false
      expect(operation.is_coming).to eq false
    end
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
      temp_document = AddTempDocumentToTempPack.execute(pack, file, options)
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
      expect(@retriever).to be_budgea_connection_failed
      expect(@retriever.budgea_error_message).to eq "Mot de passe incorrecte."
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
      expect(@retriever).to be_budgea_connection_paused
      expect(@retriever.budgea_error_message).to be_nil
    end
  end

  context 'retriever state is error' do
    before(:each) do
      @retriever.fail_budgea_connection
      @retriever.update(error_message: 'something', budgea_error_message: 'something')
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
      expect(@retriever).to be_budgea_connection_successful
      expect(@retriever.budgea_error_message).to be_nil
    end
  end

  context 'fiduceo api is active' do
    before(:each) do
      @connector.apis << 'fiduceo'
      @connector.active_apis << 'fiduceo'
      @connector.save
      @retriever.configure_fiduceo_connection
    end

    context 'no preexisting bank account' do
      it 'does not create any bank account' do
        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '0_bank_account.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        expect(@user.sandbox_bank_accounts.count).to eq 0
      end

      it 'creates a bank account and an operation' do
        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        expect(@user.sandbox_bank_accounts.count).to eq 1
        expect(@user.sandbox_operations.count).to eq 1
      end
    end

    context 'a bank account already exist' do
      before(:each) do
        @bank_account = SandboxBankAccount.new
        @bank_account.user      = @user
        @bank_account.retriever = @retriever
        @bank_account.api_id    = 17
        @bank_account.bank_name = @retriever.service_name
        @bank_account.name      = 'Compte chèque'
        @bank_account.number    = '3002900000'
        @bank_account.save
      end

      it 'does not create a new bank account, but an operation' do
        expect(@user.sandbox_bank_accounts.count).to eq 1

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        expect(@user.sandbox_bank_accounts.count).to eq 1
        expect(@user.sandbox_operations.count).to eq 1
      end

      it 'creates only one bank account, and 3 operations' do
        expect(@user.sandbox_bank_accounts.count).to eq 1

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '2_bank_accounts.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        expect(@user.sandbox_bank_accounts.count).to eq 2
        expect(@user.sandbox_operations.count).to eq 3
      end

      it 'destroys the bank account, but not the operation' do
        operation = SandboxOperation.new
        operation.user                 = @user
        operation.sandbox_bank_account = @bank_account
        operation.api_id               = 309
        operation.api_name             = 'budgea'
        operation.is_locked            = true
        operation.date                 = '2015-06-18'
        operation.value_date           = '2015-06-17'
        operation.label                = "FACTURE CB HALL'S BEER"
        operation.amount               = -16.22
        operation.comment              = nil
        operation.type_name            = 'card'
        operation.category_id          = 9998
        operation.category             = 'Indéfini'
        operation.save

        expect(@user.sandbox_bank_accounts.count).to eq 1
        expect(@user.sandbox_operations.count).to eq 1

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'destroy_bank_account.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        operation.reload
        expect(@user.sandbox_bank_accounts.count).to eq 0
        expect(operation.api_id).to be_nil
      end

      context 'an operation already exist' do
        before(:each) do
          @operation = SandboxOperation.new
          @operation.user                 = @user
          @operation.sandbox_bank_account = @bank_account
          @operation.api_id               = 309
          @operation.api_name             = 'budgea'
          @operation.is_locked            = true
          @operation.date                 = '2015-06-18'
          @operation.value_date           = '2015-06-17'
          @operation.label                = "FACTURE CB HALL'S BEER"
          @operation.amount               = -16.22
          @operation.comment              = nil
          @operation.type_name            = 'card'
          @operation.category_id          = 9998
          @operation.category             = 'Indéfini'
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
          expect(@user.sandbox_operations.count).to eq 1
          expect(@operation.label).to eq("FACTURE CB HALL'S BEER")
        end

        it 'does not create a new operation' do
          expect(@user.sandbox_operations.count).to eq 1

          retrieved_data = RetrievedData.new
          retrieved_data.user = @user
          retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
          retrieved_data.save

          ProcessRetrievedData.new(retrieved_data).execute

          expect(@user.sandbox_operations.count).to eq 1
        end

        it 'reattaches the operation to the bank account' do
          @operation.update(api_id: nil, sandbox_bank_account_id: nil)

          retrieved_data = RetrievedData.new
          retrieved_data.user = @user
          retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
          retrieved_data.save

          ProcessRetrievedData.new(retrieved_data).execute

          @operation.reload
          expect(@user.sandbox_operations.count).to eq 1
          expect(@operation.api_id).to eq '309'
          expect(@operation.sandbox_bank_account).to eq @bank_account
        end
      end
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
        expect(@user.sandbox_documents.count).to eq 0
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
        expect(@user.sandbox_documents.count).to eq 1
        expect(@user.sandbox_documents.first.content_fingerprint).to eq '97f90eac0d07fe5ade8f60a0fa54cdfc'
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
        expect(@user.sandbox_documents.count).to eq 0
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

        document = SandboxDocument.new
        document.user      = @user
        document.retriever = @retriever
        document.api_id    = 15
        document.save
      end

      it 'does not create a document' do
        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
        retrieved_data.save

        expect(@user.sandbox_documents.count).to eq 1

        VCR.use_cassette('budgea/get_document') do
          ProcessRetrievedData.new(retrieved_data).execute
        end

        @retriever.reload
        expect(retrieved_data).to be_processed
        expect(retrieved_data.processed_connection_ids).to eq [7]
        expect(@retriever).to be_ready
        expect(@user.sandbox_documents.count).to eq 1
      end
    end

    context 'retriever state is ready and fiduceo connection is synchronizing' do
      it 'changes budgea state to error' do
        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'wrong_password.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        @retriever.reload
        expect(@retriever).to be_ready
        expect(@retriever.error_message).to be_nil
        expect(@retriever).to be_budgea_connection_failed
        expect(@retriever.budgea_error_message).to eq "Mot de passe incorrecte."
        expect(@retriever.is_new_password_needed).to be true
      end

      it 'changes budgea state to paused' do
        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'waiting_additionnal_info.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        @retriever.reload
        expect(@retriever).to be_ready
        expect(@retriever.error_message).to be_nil
        expect(@retriever).to be_budgea_connection_paused
        expect(@retriever.budgea_error_message).to be_nil
      end
    end

    context 'retriever state is error, budgea connection failed and fiduceo connection is synchronizing' do
      before(:each) do
        @retriever.fail_budgea_connection
        @retriever.fail_fiduceo_connection
        @retriever.synchronize_fiduceo_connection
        @retriever.update(error_message: 'something', budgea_error_message: 'something')
      end

      it 'changes budgea state to successful' do
        @retriever.update(is_selection_needed: false)

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save

        ProcessRetrievedData.new(retrieved_data).execute

        @retriever.reload
        expect(@retriever).to be_error
        expect(@retriever.error_message).to eq 'something'
        expect(@retriever).to be_budgea_connection_successful
        expect(@retriever.budgea_error_message).to be_nil
      end
    end
  end
end
