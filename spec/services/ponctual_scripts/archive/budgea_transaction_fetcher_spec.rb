# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PonctualScripts::Archive::BudgeaTransactionFetcher do
  def prepare_user_token
    allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('VNEr6s0xI8ZIho8/zna1uNP81yxHFccb')
  end

  before(:all) do
    organization = create :organization, code: 'IDOC'
    @user = create :user, code: 'IDOC%001', organization: organization
    @retriever = create :retriever, user: @user
    @bank_account = create :bank_account, user: @user, retriever: @retriever
  end

  it 'returns log client invalid if user not found' do
    subject = PonctualScripts::Archive::BudgeaTransactionFetcher.new(nil, '1234', '2018-04-12', '2018-04-13')
    response = subject.execute

    expect(response).to match /Budgea client invalid!/
    expect(subject.send(:client)).to be nil
  end

  it 'returns invalid parameters when some parameters is missing' do
    prepare_user_token
    subject = PonctualScripts::Archive::BudgeaTransactionFetcher.new(@user, [], '2018-04-12', '2018-04-13')
    response = subject.execute

    expect(response).to match /Parameters invalid!/
    expect(subject.send(:client)).to be_a Budgea::Client
  end

  it 'returns unauthorized access when token or budgea webservice is invalid' do
    allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('FakeToken')

    subject = PonctualScripts::Archive::BudgeaTransactionFetcher.new(@user, '1234', '2018-04-12', '2018-04-13')
    response = VCR.use_cassette('budgea/unauthorize_access') do
      subject.execute
    end

    expect(response).to match /\{"code": "unauthorized"\}/
    expect(subject.send(:client)).to be_a Budgea::Client
  end

  it 'fetch all operations from budgea account, according to parameters' do
    prepare_user_token
    allow_any_instance_of(User).to receive_message_chain('retrievers.where.order.first').and_return(@retriever)
    allow_any_instance_of(User).to receive_message_chain('bank_accounts.where.first').and_return(@bank_account)

    @bank_account.bank_name = 'Paypal REST API'
    @bank_account.save

    @retriever.budgea_id = 13036
    @retriever.save

    subject = PonctualScripts::Archive::BudgeaTransactionFetcher.new(@user, '15578', '2020-04-17', '2020-04-30')
    response = VCR.use_cassette('budgea/transaction_fetcher') do
      subject.execute
    end

    expect(response).to match /New operations: 27/
  end

  context 'check transaction value nul for bank account "Paypal REST API"', :check_transaction_value do
    before(:each){ DatabaseCleaner.start }
    after(:each){ DatabaseCleaner.clean }

    def init_retrieved_data
      allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('iiEjDOvcC0lIMhmDMgZLhUTq2RbCnGKW')
      allow_any_instance_of(User).to receive_message_chain('bank_accounts.where.first').and_return(@bank_account)

      @retrieved_data = RetrievedData.new
      @retrieved_data.user = @user

      FileUtils.rm @retrieved_data.cloud_content_object.path.to_s, force: true

      @retrieved_data.json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'operations_with_transaction_attributes.json')))
      @retrieved_data.save
    end

    it 'operation with transaction value null and bank account "Paypal REST API"' do
      init_retrieved_data

      @bank_account.bank_name = 'Paypal REST API'
      @bank_account.save

      @retriever.reload
      @retriever.budgea_id       = 13036
      @retriever.name           = 'Paypal REST API'
      @retriever.service_name   = 'Paypal REST API'
      @retriever.capabilities   = 'bank'
      @retriever.save

      subject = PonctualScripts::Archive::BudgeaTransactionFetcher.new(@user, '15578', '2020-04-17', '2020-04-30')
      response = VCR.use_cassette('budgea/transaction_fetcher', preserve_exact_body_bytes: false) do
        subject.execute
      end

      second_operation = @user.operations.second

      expect(@user.operations.size).to eq 27
      expect(second_operation.label).to eq 'Paiement à Boualem Mezrar'
      expect(second_operation.is_coming).to eq false
      expect(second_operation.amount).to eq (300.0 - 15.05)
    end

    # it 'operation with bank account different of "Paypal REST API"', :paypal do
    #   init_retrieved_data

    #   @bank_account.bank_name = 'test'
    #   @bank_account.save

    #   @retriever.reload
    #   @retriever.budgea_id       = 13036
    #   @retriever.name           = 'Connecteur de test'
    #   @retriever.service_name   = 'Connecteur de test'
    #   @retriever.capabilities   = 'bank'
    #   @retriever.save

    #   subject = PonctualScripts::Archive::BudgeaTransactionFetcher.new(@user, '15578', '2020-04-17', '2020-04-30')
    #   response = VCR.use_cassette('budgea/transaction_fetcher', preserve_exact_body_bytes: false) do
    #     subject.execute
    #   end

    #   operation = @user.operations.first

    #   expect(@user.operations.count).to eq 1
    #   expect(operation.label).to eq 'Paiement à yahia mekhiouba'
    #   expect(operation.is_coming).to eq false
    #   expect(operation.amount).to eq -0.6e3
    # end
  end
end