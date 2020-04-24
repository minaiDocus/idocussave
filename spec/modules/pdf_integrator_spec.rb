# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PdfIntegrator do
  context 'simulate processed file' do
    before(:each) do
      @dir            = Dir.mktmpdir
      @file_path      = File.join(@dir, 'ACC%001_AC_202004.pdf')

      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
    end

    after(:each) do
      FileUtils.remove_entry @dir if @dir
    end

    it 'try with a normal file pdf' do
      file = File.open("#{Rails.root}/spec/support/files/upload.pdf", "r")

      processed_file = PdfIntegrator.processed_file(file, @file_path)

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.modifiable?(processed_file.path)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with protected document' do
      file = File.open("#{Rails.root}/spec/support/files/protected.pdf", "r")

      allow(DocumentTools).to receive(:protected?).with(any_args) { true }
      expect(DocumentTools).to receive(:remove_pdf_security).with(any_args).exactly(:once)

      processed_file = PdfIntegrator.processed_file(file, @file_path)

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.modifiable?(processed_file.path)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with corrupted document' do
      file = File.open("#{Rails.root}/spec/support/files/not_mergeable.pdf", "r")

      allow(DocumentTools).to receive(:modifiable?).with(any_args) { false }
      expect(PdfIntegrator).to receive(:re_create_pdf).with(any_args).exactly(:once)

      processed_file = PdfIntegrator.processed_file(file, @file_path)

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with corrupte document and recreate failed' do
      file = File.open("#{Rails.root}/spec/support/files/not_mergeable.pdf", "r")

      allow(DocumentTools).to receive(:modifiable?).with(any_args) { false }
      expect(PdfIntegrator).to receive(:force_correct_pdf).with(any_args).exactly(:once)

      processed_file = PdfIntegrator.processed_file(file, @file_path)

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with document other PDF' do
      file = File.open("#{Rails.root}/spec/support/files/large_file.png", "r")

      processed_file = PdfIntegrator.processed_file(file, @file_path)

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.modifiable?(processed_file.path)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end
  end
end