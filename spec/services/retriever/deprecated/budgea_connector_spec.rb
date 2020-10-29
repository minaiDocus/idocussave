# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Retriever::BudgeaConnector do
  before(:all) do
    Rails.cache.delete 'budgea_connector_banks'
    Rails.cache.delete 'budgea_connector_providers'
  end

  describe '.banks' do
    before(:all) do
      VCR.use_cassette('budgea/get_banks') do
        @banks = Retriever::BudgeaConnector.banks
      end
    end

    after(:all) do
      Rails.cache.delete 'budgea_connector_banks'
    end

    it 'returns a bank list' do
      expect(@banks.class).to eq Array
      @banks.each do |bank|
        expect(bank[:capabilities].include?('bank')).to be true
      end
    end

    it 'has 4 keys each' do
      @banks.each do |bank|
        expect(bank.keys).to eq ['id', 'name', 'capabilities', 'fields', 'urls']
      end
    end
  end

  describe '.providers' do
    before(:all) do
      VCR.use_cassette('budgea/get_providers') do
        @providers = Retriever::BudgeaConnector.providers
      end
    end

    after(:all) do
      Rails.cache.delete 'budgea_connector_providers'
    end

    it 'returns a provider list' do
      expect(@providers.class).to eq Array
      @providers.each do |bank|
        expect(bank[:capabilities].include?('document')).to be true
      end
    end

    it 'has 4 keys each' do
      @providers.each do |bank|
        expect(bank.keys).to eq ['id', 'name', 'capabilities', 'fields', 'urls']
      end
    end
  end

  describe '.all' do
    before(:all) do
      # VCR.use_cassette('budgea/get_banks') do
      #   @banks = Retriever::BudgeaConnector.banks
      # end

      VCR.use_cassette('budgea/get_providers') do
        @providers = Retriever::BudgeaConnector.providers
      end

      @connectors = Retriever::BudgeaConnector.all
    end

    after(:all) do
      Rails.cache.delete 'budgea_connector_banks'
      Rails.cache.delete 'budgea_connector_providers'
    end

    it 'returns a combined list of banks and providers' do
      expect(@connectors).to eq (@banks + @providers).uniq
    end
  end

  describe '.find' do
    before(:all) do
      # VCR.use_cassette('budgea/get_banks') do
      #   Retriever::BudgeaConnector.banks
      # end

      VCR.use_cassette('budgea/get_providers') do
        Retriever::BudgeaConnector.providers
      end
    end

    after(:all) do
      Rails.cache.delete 'budgea_connector_banks'
      Rails.cache.delete 'budgea_connector_providers'
    end

    it 'returns a connector' do
      connector = Retriever::BudgeaConnector.find(40)

      expect(connector[:id]).to eq 40
      expect(connector[:name]).to eq 'Connecteur de test'
    end
  end
end
