# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe UploadedDocumentPresenter do
  describe '.to_json' do
    before(:each) do
      @uploaded_document = double('uploaded_document')
      @uploaded_document.stub(:full_error_messages) { 'There are errors preventing this document to be saved.' }
      @uploaded_document.stub(:original_file_name) { 'upload.pdf' }

      @time = Time.now

      @temp_document = double('temp_document')
      @temp_document.stub(:created_at) { @time }
      @temp_document.stub(:original_file_name) { 'upload.pdf' }
      @temp_document.stub(:content_file_name) { 'TS0001_TS_201301_001.pdf' }
    end

    it "return hash of newly created document" do
      @uploaded_document.stub(:valid?) { true }
      @uploaded_document.stub(:temp_document) { @temp_document }
      presenter = UploadedDocumentPresenter.new(@uploaded_document)
      expect(presenter.to_json).to eq([{created_at: I18n.l(@time), name: 'upload.pdf', new_name: 'TS0001_TS_201301_001.pdf' }].to_json)
    end

    it "return hash error message" do
      @uploaded_document.stub(:valid?) { false }
      @uploaded_document.stub(:temp_document) { @temp_document }
      presenter = UploadedDocumentPresenter.new(@uploaded_document)
      expect(presenter.to_json).to eq([{name: 'upload.pdf', error: 'There are errors preventing this document to be saved.' }].to_json)
    end
  end
end
