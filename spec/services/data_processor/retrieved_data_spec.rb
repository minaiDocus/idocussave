# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DataProcessor::RetrievedData do
  def prepare_user_token
    allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('VNEr6s0xI8ZIho8/zna1uNP81yxHFccb')
  end

  def allow_faraday_post_connection(code, message=nil)
    allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(
      double("response", status: 200, body: { code: code, message: message, source: "ProcessRetrievedData", id: @retriever.budgea_id, fields: {field: 'test'}}.to_json)
    )
  end

  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2017,1,4))

    @organization = FactoryBot.create :organization, code: 'IDO'
    @user = FactoryBot.create(:user, code: 'IDO%0001', organization: @organization)
    @user.create_options
    @user.create_notify(
      r_wrong_pass: true,
      r_site_unavailable: true,
      r_action_needed: true,
      r_bug: true,
      r_new_documents: 'now',
      r_new_operations: 'now'
    )
    @journal = FactoryBot.create :account_book_type, user_id: @user.id
    @retriever = Retriever.new
    @retriever.user           = @user
    @retriever.budgea_id      = 7
    @retriever.budgea_connector_id = 40
    @retriever.name           = 'Connecteur de test'
    @retriever.service_name   = 'Connecteur de test'
    @retriever.journal        = @journal
    @retriever.state          = 'ready'
    @retriever.budgea_state   = 'successful'
    @retriever.capabilities   = 'bank'
    @retriever.save

    allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')

    RetrievedData.destroy_all
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'no preexisting bank account', :bank_accounts_nil do
    it 'does not create any bank account' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '0_bank_account.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 0
      expect(@user.notifications.count).to eq 0
    end

    it 'creates a bank account and an operation' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 1
      expect(@user.operations.count).to eq 1
      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Nouvelle opération'
    end
  end

  context 'a bank account already exist', :bank_accounts_exist do
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
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 1
      expect(@user.operations.count).to eq 1
      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Nouvelle opération'
    end

    it 'creates only one bank account, and 3 operations' do
      expect(@user.bank_accounts.count).to eq 1

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '2_bank_accounts.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      expect(@user.bank_accounts.count).to eq 2
      expect(@user.operations.count).to eq 3
      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.message).to match(/^3/)
    end

    it 'does not create any operation' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'deleted_operation_from_the_start.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      expect(@user.operations.count).to eq 0
      expect(@user.notifications.count).to eq 0
    end

    it 'destroys the bank account, but not the operation', :bank_accounts_destroy do
      operation = Operation.new
      operation.user         = @user
      operation.bank_account = @bank_account
      operation.organization = @organization
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
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'destroy_bank_account.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      operation.reload
      expect(@user.bank_accounts.count).to eq 0
      expect(operation.api_id).to be_nil
      expect(@user.notifications.count).to eq 0
    end

    context 'bank account has been detached from retriever' do
      before(:each) do
        @bank_account.update(retriever_id: nil)
      end

      it 're-attach the bank account to the retriever' do
        expect(@bank_account.retriever).to be_nil

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save
        DataProcessor::RetrievedData.new(retrieved_data).execute

        @bank_account.reload
        expect(@bank_account.retriever).to eq @retriever
      end
    end

    context 'an operation already exist' do
      before(:each) do
        @operation = Operation.new
        @operation.user         = @user
        @operation.bank_account = @bank_account
        @operation.organization = @organization
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
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'bank_operation_update.json')))
        retrieved_data.save

        DataProcessor::RetrievedData.new(retrieved_data).execute

        @operation.reload
        expect(@user.operations.count).to eq 1
        expect(@operation.label).to eq("FACTURE CB HALL'S BEER")
      end

      it 'destroys the operation' do
        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'remove_1_bank_operation.json')))
        retrieved_data.save

        expect(Operation.find(@operation.id)).to be_present

        DataProcessor::RetrievedData.new(retrieved_data).execute

        expect { Operation.find(@operation.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'marks the operation as deleted' do
        @operation.update(processed_at: Time.parse('2017-01-02 09:15:53'))

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'remove_1_bank_operation.json')))
        retrieved_data.save

        DataProcessor::RetrievedData.new(retrieved_data).execute

        @operation.reload

        expect(@operation.deleted_at).to eq Time.parse('2017-01-04 15:17:30')
      end

      it 'does not create a new operation' do
        expect(@user.operations.count).to eq 1

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save

        DataProcessor::RetrievedData.new(retrieved_data).execute

        expect(@user.operations.count).to eq 1
      end

      it 'reattaches the operation to the bank account' do
        @operation.update(api_id: nil, bank_account_id: nil)

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
        retrieved_data.save

        DataProcessor::RetrievedData.new(retrieved_data).execute

        @operation.reload
        expect(@user.operations.count).to eq 1
        expect(@operation.api_id).to eq '309'
        expect(@operation.bank_account).to eq @bank_account
      end

      it 'reattaches the operation to the bank account and update it' do
        @operation.update(api_id: nil, bank_account_id: nil, is_coming: true)

        retrieved_data = RetrievedData.new
        retrieved_data.user = @user
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account_updated.json')))
        retrieved_data.save

        DataProcessor::RetrievedData.new(retrieved_data).execute

        @operation.reload
        expect(@user.operations.count).to eq 1
        expect(@operation.api_id).to eq '309'
        expect(@operation.bank_account).to eq @bank_account
        expect(@operation.is_coming).to eq false
      end
    end
  end

  context '2 bank accounts already exist', :two_bank_accounts do
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
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '2_bank_accounts_and_3_operations.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      expect(@user.operations.count).to eq 3

      @operation, @operation2, @operation3 = @user.operations.to_a

      expect(@operation.api_id).to eq '1'
      expect(@operation.label).to eq 'DAB 100€'

      # should detect '[CB] ...' here
      expect(@operation2.api_id).to eq '3'
      expect(@operation2.label).to eq '[CB] RESTO 33.5€'

      expect(@operation3.api_id).to eq '2'
      expect(@operation3.label).to eq "Paypal 7.58€ #{@operation3.bank_account.number}"

      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.message).to match(/^3/)
    end

    context '3 operations already exist', :operation_already_exist do
      before(:each) do
        @operation = Operation.new
        @operation.user         = @user
        @operation.organization = @organization
        @operation.bank_account = @bank_account
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
        @operation2.organization = @organization
        @operation2.bank_account = @bank_account2
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
        @operation3.organization = @organization
        @operation3.bank_account = @bank_account
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
        retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '2_bank_accounts_and_3_operations.json')))
        retrieved_data.save

        DataProcessor::RetrievedData.new(retrieved_data).execute

        expect(@user.operations.count).to eq 3

        expect(@user.operations.first).to eq @operation
        expect(@user.operations.second).to eq @operation2
        expect(@user.operations.last).to eq @operation3

        expect(@user.operations.first.api_id).to eq '1'
        expect(@user.operations.first.bank_account).to eq @bank_account

        expect(@user.operations.second.api_id).to eq '2'
        expect(@user.operations.second.bank_account).to eq @bank_account2

        # should detect '[CB] ...' here
        expect(@user.operations.last.api_id).to eq '3'
        expect(@user.operations.last.bank_account).to eq @bank_account

        expect(@user.notifications.count).to eq 1
        expect(@user.notifications.first.message).to match(/^3/)
      end
    end
  end

  context 'a configured and used bank account exists', :configured_bank_account do
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
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '3_operations.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

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

      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.message).to match(/^3/)
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
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'update_1_operation.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      operation = @user.operations.first

      expect(operation.label).to eq 'FACTURE CB RESTO Le Bois'
      expect(operation.is_locked).to eq true
      expect(operation.is_coming).to eq true

      expect(@user.notifications.count).to eq 0
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
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'unlock_1_operation.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      operation = @user.operations.first

      expect(operation.label).to eq 'FACTURE CB RESTO Le Bois'
      expect(operation.is_locked).to eq false
      expect(operation.is_coming).to eq false

      expect(@user.notifications.count).to eq 0
    end

    it 'does not lock an operation' do
      Timecop.freeze(Time.local(2017,2,28))

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'an_old_operation.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      operation = @user.operations.first

      expect(operation.label).to eq 'Retrait DAB 100'
      expect(operation.is_locked).to eq false
      expect(operation.is_coming).to eq false

      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Nouvelle opération'

      Timecop.return
    end

    it 'does not lock recent operation' do
      Timecop.freeze(Time.local(2017,3,6))

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'an_old_operation.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      operation = @user.operations.first

      expect(operation.label).to eq 'Retrait DAB 100'
      expect(operation.is_locked).to eq false
      expect(operation.is_coming).to eq false

      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Nouvelle opération'

      Timecop.return
    end

    it 'locks 1 old operation' do
      Timecop.freeze(Time.local(2017,6,15))

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'an_old_operation.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      operation = @user.operations.first

      expect(operation.label).to eq 'Retrait DAB 100'
      expect(operation.is_locked).to eq true
      expect(operation.is_coming).to eq false

      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Nouvelle opération'

      Timecop.return
    end
  end

  context 'no preexisting document', :document_nil do
    before(:each) do
      budgea_account = BudgeaAccount.new
      budgea_account.user = @user
      budgea_account.identifier = 7
      # budgea_account.access_token = "rj3SxgMSyueBl1UVjXvWBH2gaRr/CMMl"
      # budgea_account.access_token = "CB43fRxYSTbE+hswS8yxCkWcWj8I/j2E"
      budgea_account.access_token = "R5qhEiUsjhg4BfwV0K/NWIcG5WyDdNcC5M58qkCpLYLFhdjCYMevZUa39GTEZ1d7mnIvcXbHTYf4p2PfOUZPjK9rcR2Gk7HuAzJsBzFeWEXcuAgcaOCYpSDAc1RWnfTX"
      # budgea_account.access_token = "VNEr6s0xI8ZIho8/zna1uNP81yxHFccb"
      budgea_account.save

      @retriever.capabilities   = 'document'
      @retriever.save
    end

    it 'does not create any document' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '0_document.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(retrieved_data).to be_processed
      expect(retrieved_data.processed_connection_ids).to eq [7]
      expect(@retriever).to be_ready
      expect(@user.temp_documents.count).to eq 0

      expect(@user.notifications.count).to eq 0
    end

    it 'creates a document', :create_document do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
      retrieved_data.save

      VCR.use_cassette('budgea/get_document') do
        DataProcessor::RetrievedData.new(retrieved_data).execute
      end

      @retriever.reload
      expect(retrieved_data).to be_processed
      expect(retrieved_data.processed_connection_ids).to eq [7]


      expect(@retriever).to be_waiting_selection
      expect(@user.temp_documents.count).to eq 1

      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Nouveau document'
    end

    # it 'fails to fetch document' do
    #   retrieved_data = RetrievedData.new
    #   retrieved_data.user = @user
    #   retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
    #   retrieved_data.save

    #   VCR.use_cassette('budgea/failed_to_fetch_document') do
    #     DataProcessor::RetrievedData.new(retrieved_data).execute
    #   end

    #   debugger

    #   @retriever.reload
    #   expect(@user.temp_documents.count).to eq 0
    #   expect(retrieved_data).to be_error
    #   expect(retrieved_data.error_message).to eq "[7] Document '15' cannot be downloaded : [0] "
    #   expect(retrieved_data.processed_connection_ids).to be_empty
    #   expect(@retriever).to be_error
    #   expect(@retriever.error_message).to eq "Certains documents n'ont pas pu être récupérés."

    #   expect(@user.notifications.count).to eq 0
    # end
  end

  context 'a document already exist', :document_exist do
    before(:each) do
      budgea_account = BudgeaAccount.new
      budgea_account.user = @user
      budgea_account.identifier = 7
      # budgea_account.access_token = "rj3SxgMSyueBl1UVjXvWBH2gaRr/CMMl"
      budgea_account.access_token = "CB43fRxYSTbE+hswS8yxCkWcWj8I/j2E"
      budgea_account.save

      pack = TempPack.find_or_create_by_name "#{@user.code} #{@journal.name} #{Time.now.strftime('%Y%M')}"
      options = {
        user_id:               @user.id,
        delivery_type:         'retriever',
        api_id:                115829,
        api_name:              'budgea',
        is_content_file_valid: true
      }
      file = File.open(Rails.root.join('spec', 'support', 'files', '2pages.pdf'), 'r')
      temp_document = AddTempDocumentToTempPack.execute(pack, file, options)
      @retriever.temp_documents << temp_document
      file.close

      allow_any_instance_of(TempDocument).to receive(:retrieved?).and_return(Pathname.new('/tmp'))
    end

    it 'does not create a document' do
      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
      retrieved_data.save

      expect(@user.temp_documents.count).to eq 1

      VCR.use_cassette('budgea/get_document') do
        DataProcessor::RetrievedData.new(retrieved_data).execute
      end

      @retriever.reload
      expect(retrieved_data).to be_processed
      expect(retrieved_data.processed_connection_ids).to eq [7]
      expect(@retriever).to be_ready
      expect(@user.temp_documents.count).to eq 1

      expect(@user.notifications.count).to eq 0
    end
  end

  context 'retriever state is ready', :retriever_states do
    before(:each) do
      budgea_account = BudgeaAccount.new
      budgea_account.user = @user
      budgea_account.identifier = 7
      # budgea_account.access_token = "rj3SxgMSyueBl1UVjXvWBH2gaRr/CMMl"
      # budgea_account.access_token = "CB43fRxYSTbE+hswS8yxCkWcWj8I/j2E"
      budgea_account.access_token = "R5qhEiUsjhg4BfwV0K/NWIcG5WyDdNcC5M58qkCpLYLFhdjCYMevZUa39GTEZ1d7mnIvcXbHTYf4p2PfOUZPjK9rcR2Gk7HuAzJsBzFeWEXcuAgcaOCYpSDAc1RWnfTX"
      # budgea_account.access_token = "VNEr6s0xI8ZIho8/zna1uNP81yxHFccb"
      budgea_account.save
    end

    it 'changes state to error' do
      allow_faraday_post_connection('wrongpass')

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'wrong_password.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_error
      expect(@retriever.error_message).to eq 'Mot de passe incorrect.'
      expect(@retriever).to be_budgea_connection_failed
      expect(@retriever.budgea_error_message).to eq 'wrongpass'
      expect(@retriever.is_new_password_needed).to be true
      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Mot de passe invalide'
    end

    it 'changes error_message' do
      allow_faraday_post_connection('defaults', 'La date de validité de votre mot de passe est dépassée. Veuillez le modifier.')

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'wrong_password_2.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_error
      expect(@retriever.error_message).to eq 'La date de validité de votre mot de passe est dépassée. Veuillez le modifier.'
      expect(@retriever).to be_budgea_connection_failed
      expect(@retriever.budgea_error_message).to eq 'decoupled'
    end

    it 'changes state to error because an action is needed on the web site' do
      allow_faraday_post_connection('actionNeeded', 'Please confirm the new terms and conditions')

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'action_needed.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_error
      expect(@retriever.error_message).to eq 'Please confirm the new terms and conditions'
      expect(@retriever).to be_budgea_connection_failed
      expect(@retriever.budgea_error_message).to eq 'actionNeeded'
      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Une action est nécessaire'
    end

    it 'changes state to waiting_additionnal_info' do
      allow_faraday_post_connection('additionalInformationNeeded')

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'waiting_additionnal_info.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_waiting_additionnal_info
      expect(@retriever.error_message).to be_nil
      expect(@retriever).to be_budgea_connection_paused
      expect(@retriever.budgea_error_message).to be_nil
      expect(@user.notifications.count).to eq 1
      expect(@user.notifications.first.title).to eq 'Automate - Information supplémentaire nécessaire'
    end
  end

  context 'retriever state is error', :retriever_states_2 do
    before(:each) do
      allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('FakeToken')
      allow_any_instance_of(Budgea::Client).to receive(:get_connections_log).and_return({
        'connectionlogs' => [{'id' => @retriever.budgea_id, 'error' => '', 'state' => ''}]
      })

      @retriever.fail_budgea_connection
      @retriever.update(error_message: 'something', budgea_error_message: 'something')
    end

    it 'changes state to ready' do
      @retriever.update(is_selection_needed: false)

      retrieved_data = RetrievedData.new
      retrieved_data.user = @user
      retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_bank_account.json')))
      retrieved_data.save

      DataProcessor::RetrievedData.new(retrieved_data).execute

      @retriever.reload
      expect(@retriever).to be_ready
      expect(@retriever.error_message).to be_nil
      expect(@retriever).to be_budgea_connection_successful
      expect(@retriever.budgea_error_message).to be_nil
    end
  end

  ##############################################################################
  ## 2.0
  ## DEV iDocus
  ##############################################################################

  context 'retry to get document when retriever has an error', :retry_get_file do
    before(:each) do
      TempDocument.destroy_all

      allow_any_instance_of(Budgea::Client).to receive(:get_file).and_return(Rails.root.join('spec', 'support', 'files', '3pages.pdf'))
      allow_any_instance_of(Retriever::RetrievedDocument).to receive(:valid?).and_return(true)
      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')

      json_content  = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', '1_document.json')))
      @document      = json_content['connections'][0]['subscriptions'][0]['documents'][0]
      @count_day     = 0
    end

    it 'makes successsed retry' do
      allow_any_instance_of(Budgea::Client).to receive_message_chain('response.status').and_return(200)

      Retriever::RetrievedDocument.process_file(@retriever.id, @document, @count_day)

      expect(TempDocument.last.user.id).to eq @retriever.user.id
      expect(TempDocument.last.api_name).to eq 'budgea'
      expect(TempDocument.last.delivery_type).to eq 'retriever'
      expect(TempDocument.last.delivered_by).to eq 'budgea'
      expect(TempDocument.last.api_id).to eq @document['id'].to_s
    end

    it 'return true when document is already exist', :retry_already_exist do
      allow_any_instance_of(Retriever).to receive_message_chain('temp_documents.where.first').and_return(true)

      result = Retriever::RetrievedDocument.process_file(@retriever.id, @document, @count_day)

      expect(result[:success]).to be true
      expect(TempDocument.last.try(:user).try(:id)).to eq nil
      expect(TempDocument.last.try(:api_id)).to_not eq @document['id'].to_s
    end

    it 'makes failed retry' do
      allow_any_instance_of(Budgea::Client).to receive_message_chain('response.status').and_return(401)

      Retriever::RetrievedDocument.process_file(@retriever.id, @document, @count_day)

      expect(TempDocument.last.try(:user).try(:id)).to eq nil
      expect(TempDocument.last.try(:api_id)).to_not eq @document['id'].to_s
    end
  end

  context 'check transaction value nul for bank account "Paypal REST API"', :check_transaction_value do
    def init_retrieved_data
      @retrieved_data = RetrievedData.new
      @retrieved_data.user = @user

      FileUtils.rm @retrieved_data.cloud_content_object.path.to_s, force: true

      @retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'operations_with_transaction_attributes.json')))
      @retrieved_data.save
    end

    it 'operation with transaction value null and bank account "Paypal REST API"' do
      init_retrieved_data

      @retriever.reload
      @retriever.name           = 'Paypal REST API'
      @retriever.service_name   = 'Paypal REST API'
      @retriever.capabilities   = 'bank'
      @retriever.save

      DataProcessor::RetrievedData.new(@retrieved_data).execute

      expect(@user.operations.count).to eq 2

      first_operation = @user.operations.first

      expect(first_operation.label).to eq 'Paiement à Boualem Mezrar'
      expect(first_operation.is_coming).to eq false
      expect(first_operation.amount).to eq 284.95
    end

    it 'operation with bank account different of "Paypal REST API"' do
      init_retrieved_data

      @retriever.reload
      @retriever.name           = 'Connecteur de test'
      @retriever.service_name   = 'Connecteur de test'
      @retriever.capabilities   = 'bank'
      @retriever.save

      DataProcessor::RetrievedData.new(@retrieved_data).execute

      expect(@user.operations.count).to eq 1

      second_operation = @user.operations.last

      expect(second_operation.label).to eq 'Paiement à Wafa Ali Ammar'
      expect(second_operation.is_coming).to eq false
      expect(second_operation.amount).to eq 20.0
    end

    it 'operation with transaction value, gross_value null and bank account "Paypal REST API"' do
      init_retrieved_data

      @retriever.reload
      @retriever.name           = 'Paypal REST API'
      @retriever.service_name   = 'Paypal REST API'
      @retriever.capabilities   = 'bank'
      @retriever.save

      DataProcessor::RetrievedData.new(@retrieved_data).execute

      amounts = @user.operations.collect(&:amount)

      expect(@user.operations.count).to eq 2
      expect(amounts).to eq [284.95, 20.0]
    end
  end

  context 'Budgea webhook', :budgea_webhook do
    before(:each) do
      DatabaseCleaner.start
      @organization_webhook = FactoryBot.create :organization, code: 'ICO'
      @user_webhook = FactoryBot.create(:user, code: 'ICO%0002', organization: @organization_webhook)
      @user_webhook.create_options

      @retriever_webhook = Retriever.new
      @retriever_webhook.user           = @user_webhook
      @retriever_webhook.budgea_id      = 76
      @retriever_webhook.budgea_connector_id = 59
      @retriever_webhook.name           = 'Connecteur de test'
      @retriever_webhook.service_name   = 'Connecteur de test'          
      @retriever_webhook.state          = 'ready'
      @retriever_webhook.budgea_state   = 'successful'
      @retriever_webhook.capabilities   = 'bank'
      @retriever_webhook.save

      @budgea_account = BudgeaAccount.new
      @budgea_account.user = @user_webhook
      @budgea_account.identifier = 1
      @budgea_account.access_token = 'Xhhdghsidhgius'
      @budgea_account.save
    end

    after(:each) do
      DatabaseCleaner.clean
    end
    
    it 'process user_synced callback', :user_synced do      
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'user_synced.json')))

      params = ActionController::Parameters.new(json_content)

      retriever = Retriever.where(budgea_id: json_content["connections"][0]['id']).first

      DataProcessor::RetrievedData.new(params, "USER_SYNCED", retriever.user).execute

      archive_webhook = Archive::WebhookContent.last
      
      expect(archive_webhook.synced_type).to eq "USER_SYNCED"
      expect(@user_webhook.operations.count).to eq 1
      expect(@user_webhook.operations.first.amount).to eq -0.83795e3
      expect(@user_webhook.operations.first.label).to eq 'Virement Internet'
    end

    it 'process user_deleted callback', :user_deleted  do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'user_deleted.json')))

      budgea_account_before = BudgeaAccount.where(identifier: json_content["id"]).first    

      DataProcessor::RetrievedData.new(json_content, "USER_DELETED", budgea_account_before.user).execute

      archive_webhook       = Archive::WebhookContent.last
      budgea_account_after  = BudgeaAccount.where(identifier: json_content["id"]).first

      expect(archive_webhook.synced_type).to eq "USER_DELETED"
      expect(@user_webhook.retrievers.last.state).to eq "destroying"
      expect(archive_webhook.retriever).to eq nil 
      expect(budgea_account_after).to eq nil 
    end

    it 'process connection_synced callback', :connection_synced  do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'connection_synced.json')))

      DataProcessor::RetrievedData.new(json_content, "CONNECTION_SYNCED", @user_webhook).execute

      archive_webhook = Archive::WebhookContent.last

      expect(archive_webhook.synced_type).to eq "CONNECTION_SYNCED"
      expect(@user_webhook.operations.count).to eq 1
      expect(@user_webhook.operations.first.amount).to eq -0.83795e3
      expect(@user_webhook.operations.first.label).to eq 'DEBIT MENSUEL CARTE'
    end

    it 'process connection_deleted callback', :connection_deleted  do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'connection_deleted.json')))

      DataProcessor::RetrievedData.new(json_content, "CONNECTION_DELETED", @user_webhook).execute      
      
      archive_webhook = Archive::WebhookContent.last

      expect(archive_webhook.synced_type).to eq "CONNECTION_DELETED"
      expect(@retriever_webhook.reload.state).to eq "destroying"
    end

    it 'process accounts_fetched callback', :accounts_fetched  do
      journal = FactoryBot.create :account_book_type, user_id: @user_webhook.id
      allow_any_instance_of(Retriever).to receive(:resume_me).and_return(true)

      @retriever_webhook.capabilities  = 'document'
      @retriever_webhook.journal       = journal
      @retriever_webhook.save

      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'accounts_fetched.json')))

      VCR.use_cassette('budgea/get_document') do
        DataProcessor::RetrievedData.new(json_content, "ACCOUNTS_FETCHED", @user_webhook).execute
      end

      archive_webhook = Archive::WebhookContent.last

      expect(archive_webhook.synced_type).to eq "ACCOUNTS_FETCHED"
      expect(@retriever_webhook.temp_documents.count).to eq 1
      expect(@retriever_webhook.temp_documents.last.retriever_name).to eq @retriever_webhook.name
    end
  end

  # context 'Budgea transaction fetcher', :budgea_transaction_fetcher do
  #   before(:each) do
  #     organization = create :organization, code: 'IDOC'
  #     @user_t = create :user, code: 'IDOC%001', organization: organization
  #     @retriever = create :retriever, user: @user_t
  #     @bank_account = create :bank_account, user: @user_t, retriever: @retriever
  #   end

  #   it 'returns log client invalid if user not found' do
  #     subject = DataProcessor::RetrievedData.new(nil, nil, nil)
  #     response = subject.execute_with('1234', '2018-04-12', '2018-04-13')

  #     expect(response).to match /Budgea client invalid!/
  #     expect(subject.send(:client)).to be nil
  #   end

  #   it 'returns invalid parameters when some parameters is missing' do
  #     prepare_user_token
  #     subject = DataProcessor::RetrievedData.new(nil, nil, @user_t)
  #     response = subject.execute_with([], '2018-04-12', '2018-04-13')

  #     expect(response).to match /Parameters invalid!/
  #     expect(subject.send(:client)).to be_a Budgea::Client
  #   end

  #   it 'returns unauthorized access when token or budgea webservice is invalid', :unauthorized_token do
  #     allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('FakeToken')

  #     subject = DataProcessor::RetrievedData.new(nil, nil, @user_t)
  #     response = VCR.use_cassette('budgea/unauthorize_access') do
  #       subject.execute_with('1234', '2018-04-12', '2018-04-13')
  #     end

  #     expect(response).to match /\{"code": "unauthorized"\}/
  #     expect(subject.send(:client)).to be_a Budgea::Client
  #   end

  #   it 'fetch all operations from budgea account, according to parameters', :test_1 do
  #     prepare_user_token
  #     allow_any_instance_of(User).to receive_message_chain('retrievers.where.order.first').and_return(@retriever)
  #     allow_any_instance_of(User).to receive_message_chain('bank_accounts.where.first').and_return(@bank_account)

  #     @bank_account.bank_name = 'Paypal REST API'
  #     @bank_account.save

  #     @retriever.budgea_id = 13036
  #     @retriever.save

  #     subject = DataProcessor::RetrievedData.new(nil, nil, @user_t)
  #     response = VCR.use_cassette('budgea/transaction_fetcher') do
  #       subject.execute_with('15578', '2020-04-17', '2020-04-30')
  #     end

  #     expect(response).to match /New operations: 27/
  #   end

  #   context 'check transaction value nul for bank account "Paypal REST API"', :budgea_check_transaction_value do
  #     before(:each){ DatabaseCleaner.start }
  #     after(:each){ DatabaseCleaner.clean }

  #     def init_retrieved_data
  #       allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('iiEjDOvcC0lIMhmDMgZLhUTq2RbCnGKW')
  #       allow_any_instance_of(User).to receive_message_chain('bank_accounts.where.first').and_return(@bank_account)

  #       @retrieved_data = RetrievedData.new
  #       @retrieved_data.user = @user_t

  #       FileUtils.rm @retrieved_data.cloud_content_object.path.to_s, force: true

  #       @retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'operations_with_transaction_attributes.json')))
  #       @retrieved_data.save
  #     end

  #     it 'operation with transaction value null and bank account "Paypal REST API"' do
  #       init_retrieved_data

  #       @bank_account.bank_name = 'Paypal REST API'
  #       @bank_account.save

  #       @retriever.reload
  #       @retriever.budgea_id       = 13036
  #       @retriever.name           = 'Paypal REST API'
  #       @retriever.service_name   = 'Paypal REST API'
  #       @retriever.capabilities   = 'bank'
  #       @retriever.save

  #       subject = DataProcessor::RetrievedData.new(nil, nil, @user_t)
  #       response = VCR.use_cassette('budgea/transaction_fetcher', preserve_exact_body_bytes: false) do
  #         subject.execute_with('15578', '2020-04-17', '2020-04-30')
  #       end

  #       second_operation = @user_t.operations.second

  #       expect(@user_t.operations.size).to eq 27
  #       expect(second_operation.label).to eq 'Paiement à Boualem Mezrar'
  #       expect(second_operation.is_coming).to eq false
  #       expect(second_operation.amount).to eq (300.0 - 15.05)
  #     end
  #   end
  # end
end
