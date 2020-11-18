# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe System::DatabaseCleaner do
	before(:all) do
    Timecop.freeze(Time.local(2019,12,17))

    @user             = User.create(email: "test@idocus.com", password: "123456", code: "IDO%ABC", first_name: "Service", last_name: "COMMERCIAL", company: "iDocus",  is_prescriber: false, is_fake_prescriber: false, dropbox_delivery_folder: "iDocus_delivery/:code/:year:month/:account_book/", is_dropbox_extended_authorized: false, is_centralized: true, knowings_visibility: 0, is_disabled: false, stamp_name: ":code :account_book :period :piece_num", is_stamp_background_filled: false, is_access_by_token_active: true, is_dematbox_authorized: false, is_fiduceo_authorized: false, authd_prev_period: 1, auth_prev_period_until_day: 0, auth_prev_period_until_month: 0, organization_rights_is_groups_management_authorized: true, organization_rights_is_collaborators_management_authorized: false, organization_rights_is_customers_management_authorized: true, organization_rights_is_journals_management_authorized: true, organization_rights_is_customer_journals_management_authorized: true, is_guest: false, news_read_at: "2019-03-12 10:44:22", mcf_storage: "John Doe")
    UserOptions.create(max_number_of_journals: 5, is_preassignment_authorized: true, is_taxable: true, is_pre_assignment_date_computed: -1, is_auto_deliver: -1, is_own_csv_descriptor_used: false, is_upload_authorized: true, user_id: @user.id, is_retriever_authorized: false, is_operation_processing_forced: -1, is_operation_value_date_needed: -1, preseizure_date_option: -1, dashboard_default_summary: "last_scans", is_compta_analysis_activated: -1, skip_accounting_plan_finder: false)

    byte_file64 = 'abcdefghijklmnopqrst'
    content_decode64 = StringIO.open(Base64.decode64(byte_file64))

    ## For McfDocument data

    mcf_documents = [
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test.pdf', access_token: '1234', user_id: @user.id, file64: byte_file64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test2.pdf', access_token: '12345', user_id: @user.id, file64: byte_file64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test3.pdf', access_token: '123456', user_id: @user.id, file64: byte_file64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test4.pdf', access_token: '1234567', user_id: @user.id, file64: byte_file64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test5.pdf', access_token: '12345678', user_id: @user.id, file64: byte_file64 }
		]

		mcf_documents.map {|mcf_document| McfDocument.new(mcf_document).save }

    @mcf_document =  McfDocument.all.order(created_at: :desc).limit(3)

    ## For Job Processing data

    job_processings = [
      { name:'Job processing 1', state: 'started', notifications: 'Job processing notification 1', started_at: Time.now, finished_at: Time.now },
      { name:'Job processing 2', state: 'finished', notifications: 'Job processing notification 2', started_at: Time.now, finished_at: Time.now },
      { name:'Job processing 3', state: 'killed', notifications: 'Job processing notification 2', started_at: Time.now, finished_at: Time.now },
      { name:'Job processing 4', state: 'started', notifications: 'Job processing notification 4', started_at: Time.now, finished_at: Time.now },
      { name:'Job processing 5', state: 'finished', notifications: 'Job processing notification 5', started_at: Time.now, finished_at: Time.now },
      { name:'Job processing 6', state: 'killed', notifications: 'Job processing notification 6', started_at: Time.now, finished_at: Time.now },
    ]

    job_processings.map {|job_processing| JobProcessing.new(job_processing).save }

    @job_processing =  JobProcessing.all.order(started_at: :desc).limit(3)


    ## For CurrencyRate data

    currency_rates = [
      { date: "2018-03-13 00:00:00", exchange_from: "EUR", exchange_to: "ZMW", currency_name: "Zambian Kwacha", exchange_rate: 11.9069, reverse_exchange_rate: 0.0839849, created_at: "2018-03-13 13:52:15", updated_at: "2018-03-13 13:52:15" },
      { date: "2017-05-30 00:00:00", exchange_from: "MGA", exchange_to: "USD", currency_name: "US Dollar", exchange_rate: 0.000319915, reverse_exchange_rate: 3125.83, created_at: "2018-03-09 08:18:29", updated_at: "2018-03-09 08:18:29" },
      { date: "2018-03-13 00:00:00", exchange_from: "EUR", exchange_to: "TVD", currency_name: "Tuvaluan Dollar", exchange_rate: 1.56742, reverse_exchange_rate: 0.637989, created_at: "2018-03-13 13:52:15", updated_at: "2018-03-13 13:52:15" },
    ]

    currency_rates.map {|currency_rate| CurrencyRate.new(currency_rate).save }


    ## For RetrievedData data

    retrieved_data = [
      { state: 'processed', user_id: @user.id },
      { state: 'processed', user_id: @user.id },
      { state: 'processed', user_id: @user.id }
    ]

    retrieved_data.map {|_retrieved_data| RetrievedData.new(_retrieved_data).save }

    @retrieved_data =  RetrievedData.all.order(created_at: :desc).limit(2)

  end

  after(:all) do
    Timecop.return
  end

  context 'Erase some data for records' do

	  it 'McfDocument.where("created_at < ?", 2.years.ago) deleted' do
	    
	  	mcf_updated = @mcf_document.update_all(updated_at: "2016-12-17 06:25:20", created_at: "2016-12-17 06:25:20")

	  	expect(McfDocument.all.count).to eq 5
	  	expect(mcf_updated).to eq 3

	    System::DatabaseCleaner.new.clear_all

	    mcf_count = McfDocument.all

	    expect(mcf_count.count).to eq 2
	  end

    it 'JobProccessing.where("started_at < ?", 3.month.ago) deleted' do
      
      job_processing_updated = @job_processing.update_all(started_at: "2019-08-17 06:25:20", finished_at: "2019-08-17 06:25:20")

      expect(JobProcessing.all.count).to eq 6
      expect(job_processing_updated).to eq 3

      System::DatabaseCleaner.new.clear_all

      job_processing_count = JobProcessing.all

      expect(job_processing_count.count).to eq 5
    end

    it 'RetrievedData.where("created_at < ?", 1.month.ago) deleted' do
      
      retrieved_data_updated = @retrieved_data.update_all(updated_at: "2019-10-03 06:25:20", created_at: "2019-10-03 06:25:20")

      expect(RetrievedData.all.count).to eq 3
      expect(retrieved_data_updated).to eq 2

      System::DatabaseCleaner.new.clear_all

      retrieved_data_count = RetrievedData.all

      expect(retrieved_data_count.count).to eq 1
    end

    it 'Truncate CurrencyRate when Time.now.month == 6 && Time.now.day == 1' do

      Timecop.freeze(Time.local(2019,6,1))

      expect(CurrencyRate.all.count).to eq 3

      System::DatabaseCleaner.new.clear_all

      currency_rate = CurrencyRate.all

      expect(currency_rate.count).to eq 0

      Timecop.return
    end
	end
end