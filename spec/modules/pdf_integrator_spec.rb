# -*- encoding : UTF-8 -*-
require 'spec_helper'
require 'spec_module'

describe PdfIntegrator do
  context 'simulate processed file' do
    before(:all){ SpecModule.create_tmp_dir }
    after(:all) { SpecModule.remove_tmp_dir }

    before(:each) do
      CustomUtils.mktmpdir(nil, false) do |dir|
        @dir       = dir
        @file_path = File.join(@dir, 'ACC%001_AC_202004.pdf')
      end

      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
    end

    after(:each) do
      FileUtils.remove_entry @dir if @dir
    end

    it 'try with a normal file pdf' do
      file = SpecModule.new.use_file("#{Rails.root}/spec/support/files/upload.pdf")

      expect_any_instance_of(PdfIntegrator).not_to receive(:re_create_pdf)
      expect_any_instance_of(PdfIntegrator).not_to receive(:force_correct_pdf)

      processed_file = PdfIntegrator.new(file, @file_path).processed_file

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.modifiable?(processed_file.path)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with protected document' do
      file = SpecModule.new.use_file("#{Rails.root}/spec/support/files/protected.pdf")

      allow(DocumentTools).to receive(:protected?).with(any_args).and_return(true)
      expect(DocumentTools).to receive(:remove_pdf_security).with(any_args).exactly(:once).and_call_original

      processed_file = PdfIntegrator.new(file, @file_path).processed_file

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.modifiable?(processed_file.path)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with corrupted document' do
      file = SpecModule.new.use_file("#{Rails.root}/spec/support/files/not_mergeable.pdf")

      allow(DocumentTools).to receive(:modifiable?).with(any_args).and_return(false, true)
      expect_any_instance_of(PdfIntegrator).to receive(:re_create_pdf).with(any_args).exactly(:once).and_call_original

      processed_file = PdfIntegrator.new(file, @file_path).processed_file

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with corrupted document and recreate failed' do
      file = SpecModule.new.use_file("#{Rails.root}/spec/support/files/not_mergeable.pdf")

      allow(DocumentTools).to receive(:modifiable?).with(any_args).and_return(false)
      expect_any_instance_of(PdfIntegrator).to receive(:force_correct_pdf).with(any_args).exactly(:once).and_call_original

      processed_file = PdfIntegrator.new(file, @file_path).processed_file

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end

    it 'try with document other PDF' do
      file = SpecModule.new.use_file("#{Rails.root}/spec/support/files/large_file.png")

      processed_file = PdfIntegrator.new(file, @file_path).processed_file

      expect(File.exist?(processed_file)).to eq true
      expect(DocumentTools.modifiable?(processed_file.path)).to eq true
      expect(DocumentTools.completed?(processed_file.path)).to eq true
    end
  end
end