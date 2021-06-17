# -*- encoding : UTF-8 -*-
require 'spec_helper'
require 'spec_module'

describe Archive::ResendCorruptedDocument do
  context 'simulate corrupted file' do
    before(:each) do
      DatabaseCleaner.start


      @organization = FactoryBot.create :organization, code: 'IDO'
      @user = FactoryBot.create(:user, code: 'IDO%0001', organization: @organization)      
      @journal      = FactoryBot.create :account_book_type, user: @user
      @api_name = 'worker'
      @current_user = @user
      @prev_period_offset = 0
      @analytic = nil
      @api_id = nil

      file = "#{Rails.root}/spec/support/files/corrupted.pdf"

      @file_fingerprint = DocumentTools.checksum(file)

      UploadedDocument.new(File.open(file), 'corrupted.pdf', @user, @journal.name, @prev_period_offset, @user, @api_name, @analytic,  @api_id)

      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    it 'save corrupted file to archive', :test do
      document_corrupted = Archive::DocumentCorrupted.last

      expect(document_corrupted.fingerprint).to eq @file_fingerprint
      expect(document_corrupted.retry_count).to eq 0
      expect(File.exist?(document_corrupted.cloud_content_object.reload.path)).to be true
      expect(document_corrupted.user.code).to eq 'IDO%0001'
    end

    it 'retry  to send corrupted file with success' do
      document_corrupted = Archive::DocumentCorrupted.last

      document_corrupted.retry_count = 1
      document_corrupted.save

      document_corrupted.reload
      Archive::ResendCorruptedDocument.execute

      document_corrupted = Archive::DocumentCorrupted.last

      expect(document_corrupted.fingerprint).to eq @file_fingerprint
      expect(document_corrupted.retry_count).to eq 2
      expect(File.exist?(document_corrupted.cloud_content_object.path)).to be true
      expect(document_corrupted.user.code).to eq 'IDO%0001'
    end

    it 'retry  to send corrupted file with failed and count_retry attempted' do
      document_corrupted = Archive::DocumentCorrupted.last

      document_corrupted.retry_count = 2
      document_corrupted.save

      document_corrupted.reload
      Archive::ResendCorruptedDocument.execute

      document_corrupted = Archive::DocumentCorrupted.last

      expect(document_corrupted.fingerprint).to eq @file_fingerprint
      expect(document_corrupted.retry_count).to eq 2
      expect(File.exist?(document_corrupted.cloud_content_object.path)).to be true
      expect(document_corrupted.user.code).to eq 'IDO%0001'
    end

    it 'sends notification when document is finally corrupted' do
      expect(DocumentCorruptedAlertMailer).to receive_message_chain(:notify, :deliver).with(any_args)

      document_corrupted = Archive::DocumentCorrupted.last

      document_corrupted.retry_count = 2
      document_corrupted.is_notify   = false 
      document_corrupted.save

      document_corrupted.reload
      Archive::ResendCorruptedDocument.execute

      document_corrupted = Archive::DocumentCorrupted.last

      document_corrupted.reload
      expect(document_corrupted.fingerprint).to eq @file_fingerprint
      expect(document_corrupted.retry_count).to eq 2
      expect(document_corrupted.is_notify).to be true
      expect(File.exist?(document_corrupted.cloud_content_object.path)).to be true
      expect(document_corrupted.user.code).to eq 'IDO%0001'
    end
  end    
end