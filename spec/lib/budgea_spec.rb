# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Budgea do
  before(:all) do
    @client = Budgea::Client.new
    VCR.use_cassette('budgea/create_user') do
      @client.create_user
    end
  end

  it 'creates an anonymous user successfully' do
    expect(@client.access_token.size).to eq 32
  end

  it 'gets profiles' do
    keys = ['admin', 'conf', 'contact', 'email', 'id', 'id_user', 'role', 'sponsor', 'state', 'type']
    VCR.use_cassette('budgea/get_profiles') do
      profiles = @client.get_profiles
      expect(profiles.first.keys.sort).to eq keys
    end
  end

  describe 'bank connection' do
    before(:all) do
      @connection = VCR.use_cassette('budgea/create_bank_connection') do
        params = {
          login:    'John Doe',
          password: '1234',
          website:  'par',
          id_bank:  '40'
        }
        @client.create_connection params
      end

      @accounts = VCR.use_cassette('budgea/get_accounts') do
        @client.get_accounts
      end
    end

    it 'creates a bank connection' do
      expect(@connection['error']).to be nil
      expect(@connection['error_message']).to be nil
      expect(@connection['id_bank']).to eq 40
      expect(@connection['active']).to be true
    end

    it 'updates a bank connection' do
      VCR.use_cassette('budgea/update_bank_connection') do
        updated_connection = @client.update_connection @connection['id'], login: 'John Doe 2'
        expect(updated_connection['last_update']).not_to eq(@connection['last_update'])
      end
    end

    it 'gets accounts' do
      expect(@accounts.size).to eq(4)
    end

    it 'gets transations' do
      VCR.use_cassette('budgea/get_transactions') do
        account_id = @accounts.first['id']
        transactions = @client.get_transactions(account_id)
        transaction = transactions.first
        expect(transactions.size).not_to eq 0
        expect(transaction['original_wording']).to be_present
        expect { Date.parse(transaction['date']) }.not_to raise_error
        expect { Date.parse(transaction['rdate']) }.not_to raise_error
        expect { Date.parse(transaction['application_date']) }.not_to raise_error
        expect(transaction['id_category']).to be_present
        expect(transaction['value'].class).to be Float
      end
    end

    it 'destroys bank connection' do
      VCR.use_cassette('budgea/destroy_bank_connection') do
        result = @client.destroy_connection(@connection['id'])
        expect(result).to be true
      end
    end
  end

  describe 'document retriever' do
    before(:all) do
      @connection = VCR.use_cassette('budgea/create_provider_connection') do
        params = {
          login:       'John Doe',
          password:    '1234',
          website:     'par',
          id_provider: '40'
        }
        @client.create_connection params
      end
      @documents = VCR.use_cassette('budgea/get_providers_documents') do
        @client.get_documents(@connection['id'])
      end
    end

    it 'creates a provider connection' do
      expect(@connection['error']).to be nil
      expect(@connection['error_message']).to be nil
      expect(@connection['id_provider']).to eq 40
      expect(@connection['active']).to be true
    end

    it "gets provider's documents" do
      document = @documents.first
      expect(@documents).not_to be_empty
      expect(document['name']).to be_present
      expect { Date.parse(document['date']) }.not_to raise_error
      expect { Date.parse(document['duedate']) }.not_to raise_error
      expect(document['untaxed_amount'].class).to be Float
      expect(document['vat'].class).to be Float
      expect(document['total_amount'].class).to be Float
    end

    it 'gets a file' do
      VCR.use_cassette('budgea/get_file') do
        temp_path = @client.get_file @documents.first['id']
        expect(File.file?(temp_path)).to be true
      end
    end
  end

  it 'destroy an anonymous user successfully' do
    VCR.use_cassette('budgea/destroy_user') do
      expect(@client.destroy_user).to be true
    end
    expect(@client.access_token).to be nil
  end

  it 'gets banks list successfully' do
    keys = ['beta', 'capabilities', 'charged', 'code', 'color', 'fields', 'hidden', 'id', 'id_category', 'name', 'slug']
    VCR.use_cassette('budgea/get_banks') do
      client = Budgea::Client.new
      banks = client.get_banks

      expect(banks.size).not_to eq 0
      banks.each do |bank|
        expect(bank.keys.sort).to eq keys
      end
    end
  end

  it 'gets providers list successfully' do
    keys = ['beta', 'capabilities', 'charged', 'code', 'color', 'fields', 'hidden', 'id', 'id_category', 'name', 'slug']
    VCR.use_cassette('budgea/get_providers') do
      client = Budgea::Client.new
      providers = client.get_providers

      expect(providers.size).not_to eq 0
      providers.each do |provider|
        expect(provider.keys.sort).to eq keys
      end
    end
  end

  it 'gets categories list successfully' do
    keys = ['accountant_account', 'checkable', 'children', 'color', 'hidden', 'id', 'id_logo', 'id_parent_category', 'id_parent_category_in_menu', 'id_user', 'income', 'name', 'name_displayed', 'refundable']
    VCR.use_cassette('budgea/get_categories') do
      client = Budgea::Client.new
      categories = client.get_categories

      expect(categories.size).not_to eq 0
      categories.each do |category|
        expect(category.keys.sort).to eq keys
      end
    end
  end
end
