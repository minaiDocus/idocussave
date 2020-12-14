# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe RetrieversController do
  before (:each) do 
    DatabaseCleaner.start
    allow_any_instance_of(DataProcessor::RetrievedData).to receive(:execute).and_return(true)
    allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')

    @organization = FactoryBot.create :organization, code: 'IDO'
    @user = FactoryBot.create(:user, code: 'IDO%0001', organization: @organization)
    @user.create_options

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
  end

  after(:each) do 
    DatabaseCleaner.clean
  end

  context "budgea connector synced", :list_piece do
    it "user sync success" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'user_synced.json')))

      post :user_synced, format: 'json', params: json_content

      expect(response).to be_successful
      expect(response.code).to eq('200')
    end

    it "user sync failed" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'user_synced failed.json')))

      post :user_synced, format: 'json', params: json_content

      expect(response).not_to be_successful
      expect(response.code).to eq('400')
    end

    it "user_deleted success" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'user_deleted.json')))

      post :user_deleted, format: 'json', params: json_content

      expect(response).to be_successful
      expect(response.code).to eq('200')
    end

    it "user_deleted failed", :user_delete do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'user_deleted failed.json')))

      post :user_deleted, format: 'json', params: json_content

      expect(response).not_to be_successful
      expect(response.code).to eq('400')
    end

    it "connection_synced success", :test do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'connection_synced.json')))

      
      post :connection_synced, format: 'json', params: json_content

      expect(response).to be_successful
      expect(response.code).to eq('200')
    end

    it "connection_synced failed" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'connection_synced failed.json')))

      post :connection_synced, format: 'json', params: json_content

      expect(response).not_to be_successful
      expect(response.code).to eq('400')
    end

    it "connection_deleted success" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'connection_deleted.json')))

      post :connection_deleted, format: 'json', params: json_content

      expect(response).to be_successful
      expect(response.code).to eq('200')
    end

    it "connection_deleted failed" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'connection_deleted failed.json')))

      post :connection_deleted, format: 'json', params: json_content

      expect(response).not_to be_successful
      expect(response.code).to eq('400')
    end

    it "accounts_fetched success" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'accounts_fetched.json')))

      post :accounts_fetched, format: 'json', params: json_content

      expect(response).to be_successful
      expect(response.code).to eq('200')
    end

    it "accounts_fetched failed" do
      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'accounts_fetched failed.json')))

      post :accounts_fetched, format: 'json', params: json_content

      expect(response).not_to be_successful
      expect(response.code).to eq('400')
    end
  end
end