# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe BudgeaTransactionFetcher do
  def prepare_user_token
    allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('VNEr6s0xI8ZIho8/zna1uNP81yxHFccb')
  end

  before(:all) do
    organization = create :organization, code: 'IDOC'
    @user = create :user, code: 'IDOC%001', organization: organization
    @retriever = create :retriever
    @bank_account = create :bank_account, user: @user, retriever: @retriever
    connector = create :connector
    connector.retrievers << @retriever
  end

  it 'returns log client invalid if user not found' do
    subject = BudgeaTransactionFetcher.new(nil, '1234', '2018-04-12', '2018-04-13')
    response = subject.execute

    expect(response).to match /Budgea client invalid!/
    expect(subject.send(:client)).to be nil
  end

  it 'returns invalid parameters when some parameters is missing' do
    prepare_user_token
    subject = BudgeaTransactionFetcher.new(@user, [], '2018-04-12', '2018-04-13')
    response = subject.execute

    expect(response).to match /Parameters invalid!/
    expect(subject.send(:client)).to be_a Budgea::Client
  end

  it 'returns unauthorized access when token or budgea webservice is invalid' do
    allow_any_instance_of(User).to receive_message_chain('budgea_account.access_token').and_return('FakeToken')

    subject = BudgeaTransactionFetcher.new(@user, '1234', '2018-04-12', '2018-04-13')
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

    subject = BudgeaTransactionFetcher.new(@user, '12536', '2018-04-12', '2018-04-13')
    response = VCR.use_cassette('budgea/transaction_fetcher') do
      subject.execute
    end

    expect(response).to match /New operations: 4/
  end
end