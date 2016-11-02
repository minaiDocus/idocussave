# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe 'Retrievers' do
  before(:all) do
    @user = FactoryGirl.create :user, code: 'IDO%0001'
    @user.options = UserOptions.create(user_id: @user.id)

    VCR.use_cassette('budgea/create_budgea_acount') do
      CreateBudgeaAccount.execute(@user)
    end

    VCR.use_cassette('budgea/get_providers') do
      RetrieverProvider.new.providers
    end

    VCR.use_cassette('budgea/get_banks') do
      RetrieverProvider.new.banks
    end

    @retriever = Retriever.new
    @retriever.user = @user
    @retriever.connector_id = 40
    @retriever.service_name = 'Connecteur de test'
    @retriever.type = 'bank'
    @retriever.name = 'Connecteur de test'
    @retriever.param1 = {
      name: 'website',
      type: 'list',
      value: 'par'
    }
    @retriever.param2 = {
      name: 'login',
      type: 'text',
      value: 'John Doe'
    }
    @retriever.param3 = {
      name: 'password',
      type: 'password',
      value: '1234'
    }
    @retriever.save
    @retriever.reload
  end

  it 'creates a retriever connection successfully' do
    expect(@retriever.state).to eq 'creating'
    VCR.use_cassette('budgea/create_retriever_connection') do
      CreateRetrieverConnection.execute(@retriever)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_present
    expect(@retriever.param3).to be_nil
    expect(@retriever.api_id).to be_present
    expect(@retriever.state).to eq 'ready'
  end

  it 'updates a retriever connection successfully' do
    @retriever.param2 = {
      name: 'login',
      type: 'text',
      value: 'John Doe 2'
    }
    @retriever.save
    @retriever.reload
    @retriever.update_connection

    expect(@retriever.state).to eq 'updating'
    VCR.use_cassette('budgea/update_retriever_connection') do
      UpdateRetrieverConnection.execute(@retriever)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_present
    expect(@retriever.param3).to be_nil
    expect(@retriever.state).to eq 'ready'
  end

  it 'destroys a retriever connection successfully' do
    VCR.use_cassette('budgea/destroy_retriever_connection') do
      DestroyRetrieverConnection.execute(@retriever)
    end
    expect(@retriever).to be_destroyed
  end
end
