# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe UploadedDocumentPresenter do
  describe '.to_json' do
    before(:each) do
      @uploaded_document = double('uploaded_document')
      allow(@uploaded_document).to receive(:full_error_messages) { 'There are errors preventing this document to be saved.' }
      allow(@uploaded_document).to receive(:original_file_name) { 'upload.pdf' }

      @time = Time.now

      @temp_document = double('temp_document')
      allow(@temp_document).to receive(:state) { 'ready' }
      allow(@temp_document).to receive(:created_at) { @time }
      allow(@temp_document).to receive(:original_file_name) { 'upload.pdf' }
      allow(@temp_document).to receive(:content_file_name) { 'TS0001_TS_201301_001.pdf' }
    end

    it "return hash of newly created document" do
      allow(@uploaded_document).to receive(:valid?) { true }
      allow(@uploaded_document).to receive(:temp_document) { @temp_document }
      presenter = UploadedDocumentPresenter.new(@uploaded_document)
      expect(presenter.to_json).to eq([{created_at: I18n.l(@time), name: 'upload.pdf', new_name: 'TS0001_TS_201301_001.pdf' }].to_json)
    end

    it "return hash of newly created document with pre assignment notice" do
      allow(@temp_document).to receive(:state) { 'bundle_needed' }
      allow(@uploaded_document).to receive(:valid?) { true }
      allow(@uploaded_document).to receive(:temp_document) { @temp_document }
      presenter = UploadedDocumentPresenter.new(@uploaded_document)
      result = [
        {
          created_at: I18n.l(@time),
          name:       'upload.pdf',
          new_name:   'TS0001_TS_201301_001.pdf',
          message:    'vos documents sont en-cours de traitement, ils seront visibles dans quelques heures dans votre espace'
        }
      ]
      expect(presenter.to_json).to eq(result.to_json)
    end

    it "return hash error message" do
      allow(@uploaded_document).to receive(:valid?) { false }
      allow(@uploaded_document).to receive(:temp_document) { @temp_document }
      presenter = UploadedDocumentPresenter.new(@uploaded_document)
      expect(presenter.to_json).to eq([{name: 'upload.pdf', error: 'There are errors preventing this document to be saved.' }].to_json)
    end
  end
end
