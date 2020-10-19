# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DataProcessor::Mcf do
  before(:each) do
    @user             = User.create(email: "test@idocus.com", password: "123456", code: "IDO%ABC", first_name: "Service", last_name: "COMMERCIAL", company: "iDocus",  is_prescriber: false, is_fake_prescriber: false, dropbox_delivery_folder: "iDocus_delivery/:code/:year:month/:account_book/", is_dropbox_extended_authorized: false, is_centralized: true, knowings_visibility: 0, is_disabled: false, stamp_name: ":code :account_book :period :piece_num", is_stamp_background_filled: false, is_access_by_token_active: true, is_dematbox_authorized: false, is_fiduceo_authorized: false, authd_prev_period: 1, auth_prev_period_until_day: 0, auth_prev_period_until_month: 0, organization_rights_is_groups_management_authorized: true, organization_rights_is_collaborators_management_authorized: false, organization_rights_is_customers_management_authorized: true, organization_rights_is_journals_management_authorized: true, organization_rights_is_customer_journals_management_authorized: true, is_guest: false, news_read_at: "2019-03-12 10:44:22", mcf_storage: "John Doe")
    UserOptions.create(max_number_of_journals: 5, is_preassignment_authorized: true, is_taxable: true, is_pre_assignment_date_computed: -1, is_auto_deliver: -1, is_own_csv_descriptor_used: false, is_upload_authorized: true, user_id: @user.id, is_retriever_authorized: false, is_operation_processing_forced: -1, is_operation_value_date_needed: -1, preseizure_date_option: -1, dashboard_default_summary: "last_scans", is_compta_analysis_activated: -1, skip_accounting_plan_finder: false)

    params_attributes = { :code => "IDO%ABC", :journal => "AC", :file64 => "abcdefghijklmnopqrst", :original_file_name => "test.pdf", :access_token => "123"
                                        }
    @mcf_document =  McfDocument.create_or_initialize_with(params_attributes)

    @process_return = double
    allow(UploadedDocument).to receive(:new).and_return(@process_return)
  end

  after(:each) do
    McfDocument.destroy_all
    UserOptions.destroy_all
    User.destroy_all
  end

  context 'After receiving file' do

    it 'Store byte file decoded to content McfDocument#create_or_initialize_with', :update_attr do
      allow(@process_return).to receive(:valid?).and_return(true)
      DataProcessor::Mcf.new(@mcf_document).execute_process

      expect(@mcf_document.cloud_content_object.filename).to eq 'test.pdf'
      expect(@mcf_document.cloud_content_object.path).to match /tmp\/McfDocument\/([0-9]{8})\/([0-9]+)\/test\.pdf/
      expect(@mcf_document.file64).to be nil
      expect(@mcf_document.user).to eq @user
    end

    it 'Requests a new file to MCF if content is nil', :request_resend_file do
      allow(@mcf_document).to receive_message_chain('cloud_content', 'attached?').and_return(false)

      DataProcessor::Mcf.new(@mcf_document).execute_process

      expect(@mcf_document.state).to eq 'needs_retake'
      expect(@mcf_document.retake_at).not_to be nil
    end

    it 'Mark files as "needs_retake" when file is corrupted', :corrupted do
      allow(@process_return).to receive(:valid?).and_return(false)
      allow(@process_return).to receive(:already_exist?).and_return(false)
      allow(@process_return).to receive(:errors).and_return([[:file_is_corrupted_or_protected, nil]])
      allow(@process_return).to receive(:full_error_messages).and_return(nil)

      DataProcessor::Mcf.new(@mcf_document).execute_process

      expect(@mcf_document.is_generated).to be true
      expect(@mcf_document.state).to eq 'needs_retake'
      expect(@mcf_document.error_message).to be nil
    end

    it 'Mark files as unprocessable when errors occure', :unprocessable do
      allow(@user).to receive(:create_options).and_return(true)
      allow(@process_return).to receive(:valid?).and_return(false)
      allow(@process_return).to receive(:already_exist?).and_return(false)
      allow(@process_return).to receive(:errors).and_return([[:journal_unknown, journal: "TST"]])
      allow(@process_return).to receive(:full_error_messages).and_return("journal TST introuvable")

      DataProcessor::Mcf.new(@mcf_document).execute_process

      expect(@mcf_document.is_generated).to be true
      expect(@mcf_document.state).to eq 'not_processable'
      expect(@mcf_document.error_message).to eq 'journal TST introuvable'
    end

    it 'Mark files as processed if everything is ok', :processed do
      allow(@process_return).to receive(:valid?).and_return(true)

      DataProcessor::Mcf.new(@mcf_document).execute_process

      expect(@mcf_document.is_generated).to be true
      expect(@mcf_document.state).to eq 'processed'
    end

    it 'returns state: "needs_retake" when content is nil', :needs_retake do
      allow(@mcf_document).to receive_message_chain('cloud_content', 'attached?').and_return(false)
      @mcf_document.update(is_generated: false)
      @mcf_document.reload

      DataProcessor::Mcf.new(@mcf_document).execute_process

      expect(@mcf_document.state).to eq 'needs_retake'
      expect(@mcf_document.retake_at).not_to be nil
    end
  end

  context 'Logs' do
    before(:each) do
      @log_file = "#{Rails.root}/log/#{Rails.env}_mcf_processing.log"
      File.unlink(@log_file) if File.exist? @log_file
    end

    it 'File 64 successfully processed', :success do
      allow(@process_return).to receive(:valid?).and_return(true)

      DataProcessor::Mcf.new(@mcf_document).execute_process

      log_content = File.read(@log_file)

      expect(File.exist?(@log_file)).to be true
      expect(log_content).to match /FILE PROCESSED/i
    end

    it 'File 64 is failed to upload in content', :failed do
      allow(@user).to receive(:create_options).and_return(true)
      allow(@process_return).to receive(:valid?).and_return(false)
      allow(@process_return).to receive(:already_exist?).and_return(false)
      allow(@process_return).to receive(:errors).and_return([[:journal_unknown, journal: "TST"]])
      allow(@process_return).to receive(:full_error_messages).and_return("journal TST introuvable")

      DataProcessor::Mcf.new(@mcf_document).execute_process

      log_content = File.read(@log_file)

      expect(File.exist?(@log_file)).to be true
      expect(log_content).to match /FILE PROCESS ERROR/i
    end
  end
end