# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DatabaseCleanerService do
	before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2019,12,17))

    @user             = User.create(email: "test@idocus.com", password: "123456", code: "IDO%ABC", first_name: "Service", last_name: "COMMERCIAL", company: "iDocus",  is_prescriber: false, is_fake_prescriber: false, dropbox_delivery_folder: "iDocus_delivery/:code/:year:month/:account_book/", is_dropbox_extended_authorized: false, is_centralized: true, knowings_visibility: 0, is_disabled: false, stamp_name: ":code :account_book :period :piece_num", is_stamp_background_filled: false, is_access_by_token_active: true, is_dematbox_authorized: false, is_fiduceo_authorized: false, authd_prev_period: 1, auth_prev_period_until_day: 0, auth_prev_period_until_month: 0, organization_rights_is_groups_management_authorized: true, organization_rights_is_collaborators_management_authorized: false, organization_rights_is_customers_management_authorized: true, organization_rights_is_journals_management_authorized: true, organization_rights_is_customer_journals_management_authorized: true, is_guest: false, news_read_at: "2019-03-12 10:44:22", mcf_storage: "John Doe")
    UserOptions.create(max_number_of_journals: 5, is_preassignment_authorized: true, is_taxable: true, is_pre_assignment_date_computed: -1, is_auto_deliver: -1, is_own_csv_descriptor_used: false, is_upload_authorized: true, user_id: @user.id, is_retriever_authorized: false, is_operation_processing_forced: -1, is_operation_value_date_needed: -1, preseizure_date_option: -1, dashboard_default_summary: "last_scans", is_compta_analysis_activated: -1, skip_accounting_plan_finder: false)

    byte_file64 = 'abcdefghijklmnopqrst'
    content_decode64 = StringIO.open(Base64.decode64(byte_file64))

    mcf_documents = [
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test.pdf', access_token: '1234', user_id: @user.id, content: content_decode64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test2.pdf', access_token: '12345', user_id: @user.id, content: content_decode64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test3.pdf', access_token: '123456', user_id: @user.id, content: content_decode64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test4.pdf', access_token: '1234567', user_id: @user.id, content: content_decode64 },
			{ code: 'IDO%ABC', journal: 'AC', original_file_name: 'test5.pdf', access_token: '12345678', user_id: @user.id, content: content_decode64 }
		]

		mcf_documents.map {|mcf_document| McfDocument.new(mcf_document).save }

    @mcf_document =  McfDocument.all.order(created_at: :desc).limit(3)
  end

  after(:each) do
    DatabaseCleaner.clean
    Timecop.return
  end

  context 'Erase all McfDocument records when created date are more than two years ago' do

	  it 'return 2 records when McfDocument.where("created_at < ?", 2.years.ago) deleted ' do
	    
	  	mcf_updated = @mcf_document.update_all(updated_at: "2016-12-17 06:25:20", created_at: "2016-12-17 06:25:20")

	  	expect(McfDocument.all.count).to eq 5
	  	expect(mcf_updated).to eq 3

	    DatabaseCleanerService.clear_all

	    mcf_count = McfDocument.all

	    expect(mcf_count.count).to eq 2
	  end
	end
end