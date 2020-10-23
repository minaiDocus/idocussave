# -*- encoding : UTF-8 -*-
require 'spec_helper'
require 'spec_module'

describe Ibizabox::Document do
  before(:all){ SpecModule.create_tmp_dir }
  after(:all) { SpecModule.remove_tmp_dir }

  before(:each){ DatabaseCleaner.start }
  after(:each) { DatabaseCleaner.clean }

  context 'Make file for temp_document' do
    it 'creates temp document file' do
      file    = SpecModule.new.use_file("#{Rails.root}/spec/support/files/upload.pdf")
      user    = FactoryBot.create(:user)
      journal = FactoryBot.create(:account_book_type)
      organization = FactoryBot.create(:organization)
      @folder = FactoryBot.create(:ibizabox_folders, user: user, journal: journal)

      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
      allow_any_instance_of(TempPack).to receive(:organization) { organization }

      Ibiza::IbizaboxDocument.new(file, @folder, 125, 0)

      expect(TempDocument.last.original_fingerprint).to be_present
      expect(TempDocument.last.user.id).to eq @folder.user.id
      expect(TempDocument.last.api_name).to eq 'ibiza'
      expect(TempDocument.last.delivery_type).to eq 'upload'
      expect(TempDocument.last.delivered_by).to eq 'ibiza'
      expect(TempDocument.last.api_id).to eq "125"
      expect(TempDocument.last.cloud_content.attached?).to be true
    end

    it 'blocks duplicated document, (document already exist)' do
      file    = SpecModule.new.use_file("#{Rails.root}/spec/support/files/upload.pdf")
      user    = FactoryBot.create(:user)
      journal = FactoryBot.create(:account_book_type)
      organization = FactoryBot.create(:organization)
      @folder = FactoryBot.create(:ibizabox_folders, user: user, journal: journal)

      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
      allow_any_instance_of(TempPack).to receive(:organization) { organization }

      Ibizabox::Document.new(file, @folder, 125, 0)
      Ibizabox::Document.new(file, @folder, 126, 0)

      expect(TempDocument.count).to eq 1
      expect(TempDocument.last.user.id).to eq @folder.user.id
      expect(TempDocument.last.api_name).to eq 'ibiza'
      expect(TempDocument.last.delivery_type).to eq 'upload'
      expect(TempDocument.last.delivered_by).to eq 'ibiza'
      expect(TempDocument.last.api_id).to eq "125"
      expect(TempDocument.last.cloud_content.attached?).to be true
      expect(TempDocument.last.original_fingerprint).to be_present
    end
  end
end