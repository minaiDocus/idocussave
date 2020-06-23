# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe BudgeaErrorEventHandlerService do
  before(:all) do
    DatabaseCleaner.start

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
    @retriever.budgea_id      = 13139
    @retriever.budgea_connector_id = 40
    @retriever.name           = 'Connecteur de test'
    @retriever.service_name   = 'Connecteur de test'
    @retriever.journal        = @journal
    @retriever.state          = 'error'
    @retriever.budgea_state   = 'failed'
    @retriever.capabilities   = 'bank'
    @retriever.sync_at        = Time.now
    @retriever.save

    budgea_account              = BudgeaAccount.new
    budgea_account.user         = @user
    budgea_account.identifier   = 13139
    budgea_account.access_token = "CB43fRxYSTbE+hswS8yxCkWcWj8I/j2E"
    budgea_account.save

    RetrievedData.destroy_all
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  before(:each) do
    allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
  end

  context 'get retrievers to refresh' do
    it 'get scarequired refresh launcher' do
      @retriever.budgea_error_message = 'SCARequired'
      @retriever.save

      allow_any_instance_of(Retriever).to receive(:update_state_with).with(any_args).and_return(true)
      expect_any_instance_of(Budgea::Client).to receive(:scaRequired_refresh).with(any_args).exactly(:once)

      VCR.use_cassette('budgea/refresh_scarequired') do
        BudgeaErrorEventHandlerService.new().execute
      end
    end

    it 'get decoupled refresh launcher' do
      @retriever.budgea_error_message = 'decoupled'
      @retriever.save

      allow_any_instance_of(Retriever).to receive(:update_state_with).with(any_args).and_return(true)
      expect_any_instance_of(Budgea::Client).to receive(:decoupled_refresh).with(any_args).exactly(:once)

      VCR.use_cassette('budgea/refresh_decoupled') do
        BudgeaErrorEventHandlerService.new().execute
      end
    end

    it "updates state of retriever to success if connection response is nil" do
      time = Time.now

      @retriever.budgea_error_message = 'SCARequired'
      @retriever.sync_at              = time
      @retriever.save

      VCR.use_cassette('budgea/inspect_other_errors') do
        BudgeaErrorEventHandlerService.new().execute
      end

      @retriever.reload

      expect(@retriever.budgea_connection_successful?).to be true
      expect(@retriever.sync_at).not_to eq(time)
    end

    it "updates state to SCARequired when refreshing return error is SCARequired" do
      time = Time.now

      @retriever.budgea_error_message = 'decoupled'
      @retriever.sync_at = time
      @retriever.save

      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'scarequired_error.json')))
      allow_any_instance_of(Budgea::Client).to receive(:decoupled_refresh).with(any_args).and_return(json_content)

      VCR.use_cassette('budgea/inspect_other_errors') do
        BudgeaErrorEventHandlerService.new().execute
      end

      @retriever.reload

      expect(@retriever.budgea_connection_successful?).to be false
      expect(@retriever.budgea_error_message).to eq 'SCARequired'
      expect(@retriever.sync_at).not_to eq(time)
    end

    it "updates state to SCARequired when refreshing return error is decoupled" do
      time = Time.now

      @retriever.budgea_error_message = 'SCARequired'
      @retriever.sync_at = time
      @retriever.save

      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'decoupled_error.json')))
      allow_any_instance_of(Budgea::Client).to receive(:scaRequired_refresh).with(any_args).and_return(json_content)

      VCR.use_cassette('budgea/inspect_other_errors') do
        BudgeaErrorEventHandlerService.new().execute
      end

      @retriever.reload

      expect(@retriever.budgea_connection_successful?).to be false
      expect(@retriever.budgea_error_message).to eq 'decoupled'
      expect(@retriever.sync_at).not_to eq(time)
    end

    it "updates retriver's state to error (other errors) when refreshing state returns error" do
      time = Time.now

      @retriever.budgea_error_message = 'SCARequired'
      @retriever.sync_at = time
      @retriever.save

      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'other_error.json')))
      allow_any_instance_of(Budgea::Client).to receive(:scaRequired_refresh).with(any_args).and_return(json_content)

      VCR.use_cassette('budgea/inspect_other_errors') do
        BudgeaErrorEventHandlerService.new().execute
      end

      @retriever.reload

      expect(@retriever.budgea_connection_successful?).to be false
      expect(@retriever.budgea_error_message).to eq 'Other error'
      expect(@retriever.sync_at).not_to eq(time)
    end


    it "does not make any changes if update params is nil" do
      @retriever.budgea_error_message = 'SCARequired'
      @retriever.sync_at = Time.now
      @retriever.save

      initial_state = @retriever

      allow_any_instance_of(Budgea::Client).to receive(:scaRequired_refresh).with(any_args).and_return(nil)

      VCR.use_cassette('budgea/inspect_other_errors') do
        BudgeaErrorEventHandlerService.new().execute
      end

      @retriever.reload

      expect(@retriever.inspect).to eq initial_state.inspect
    end

    it "call decoupled_refresh function when error's scarequired", :sca do
      @retriever.budgea_error_message = 'SCARequired'
      @retriever.sync_at = Time.now
      @retriever.save

      json_content = JSON.parse(File.read(Rails.root.join('spec', 'support', 'budgea', 'decoupled_error.json')))
      allow_any_instance_of(Budgea::Client).to receive(:scaRequired_refresh).with(any_args).and_return(json_content)
      allow_any_instance_of(BudgeaErrorEventHandlerService).to receive(:prepare_notification).with(any_args).and_return(true)
      allow_any_instance_of(BudgeaErrorEventHandlerService).to receive(:send_notification).with(any_args).and_return(true)

      expect_any_instance_of(Retriever).to receive(:update_state_with).with(any_args).exactly(:once)
      expect(BudgeaErrorEventHandlerService).to receive_message_chain('new.execute').with(any_args).exactly(:once)

      VCR.use_cassette('budgea/inspect_other_errors') do
        BudgeaErrorEventHandlerService.new().execute
      end

    end
  end
end