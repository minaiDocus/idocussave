# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe 'Retrievers' do
  before(:all) do
    @user = FactoryGirl.create :user, code: 'IDO%0001'
    @params = {
      bank_id:      40,
      type:         'bank',
      service_name: 'Connecteur de test',
      name:         'Banque 1',
      login:        'John Doe',
      password:     '1234',
      extra_params: {
        website: 'par'
      }
    }
    # @retriever = Retriever.new params
    # @retriever.user = @user
    # @retriever.save
  end

  it 'creates a retriever successfully' do
    VCR.use_cassette('budgea/create_retriever_connection') do
      retriever = CreateRetriever.with(@user, @params)
      expect(retriever).to be_persisted
    end
  end

  # it 'creates a retriever connection successfully' do
  #   connection = CreateRetrieverConnection.new(@retriever)
  #   VCR.use_cassette('budgea/create_retriever_connection') do
  #     expect(@retriever.state).to eq 'processing'
  #     expect(connection.create).to be true
  #     expect(@retriever.budgea_id).to be_present
  #     expect(@retriever.state).to eq 'ready'
  #   end
  # end

  # it 'updates a retriever connection successfully' do
  #   @retriever.login = 'John Doe 2'
  #   @retriever.password = nil
  #   @retriever.extra_params = { website: 'pro' }
  #   @retriever.save
  #   @retriever.process
  #   connection = UpdateRetrieverConnection.new(@retriever)
  #   VCR.use_cassette('budgea/update_retriever_connection') do
  #     expect(connection.update).to be true
  #     expect(@retriever.state).to eq 'ready'
  #   end
  # end

  # it 'destroys a retriever connection successfully' do
  #   VCR.use_cassette('budgea/destroy_retriever_connection') do
  #     expect(DestroyRetrieverConnection.new(@retriever).destroy).to be true
  #   end
  #   expect(@retriever).to be_destroyed
  # end
end
