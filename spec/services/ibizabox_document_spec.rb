# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe IbizaboxDocument do
  context 'Make file for temp_document' do
    it 'create temp document file' do
      file    = File.open("#{Rails.root}/spec/support/files/upload.pdf", "r")
      user    = FactoryBot.create(:user)
      journal = FactoryBot.create(:account_book_type)
      organization = FactoryBot.create(:organization)
      @folder = FactoryBot.create(:ibizabox_folders, user: user, journal: journal)

      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
      allow_any_instance_of(TempPack).to receive(:organization) { organization }

      IbizaboxDocument.new(file, @folder, 125, 0)

      expect(TempDocument.last.user.id).to eq @folder.user.id
      expect(TempDocument.last.api_name).to eq 'ibiza'
      expect(TempDocument.last.delivery_type).to eq 'upload'
      expect(TempDocument.last.delivered_by).to eq 'ibiza'
      expect(TempDocument.last.api_id).to eq "125"
    end
  end
end