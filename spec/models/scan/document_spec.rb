# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Scan::Document do
  before(:each) do
    @period = Scan::Period.create!(:start_at => Time.now, :end_in => 1)
    @document_name = "TS0001 XX #{Time.now.strftime('%Y%m')} all"
    @document_name2 = "TS0001 ZZ #{Time.now.strftime('%Y%m')} all"
  end

  it "should create valid entry" do
    document = Scan::Document.new(:name => @document_name)
    document.period = @period
    document.save
    document.should be_persisted
  end
  
  it "should verify scanned count" do
    document = Scan::Document.new(:name => @document_name)
    document.period = @period
    document.pieces = 30
    document.sheets = 30
    document.pages = 80
    document.uploaded_pieces = 5
    document.uploaded_sheets = 5
    document.uploaded_pages = 30
    document.save
    
    document.scanned_pieces.should eq(25)
    document.scanned_sheets.should eq(25)
    document.scanned_pages.should eq(50)
  end
  
  it "should find document named \"#{@document_name}\"" do
    document = Scan::Document.new(:name => @document_name)
    document.period = @period
    document.save
    
    document2 = Scan::Document.new(:name => "TS0001 XX #{(Time.now - 1.month).strftime('%Y%m')} all")
    document2.period = @period
    document2.save
    
    result = Scan::Document.find_by_name(@document_name)
    result.should eq(document)
    result.should_not eq(document2)
  end

  describe ".find_or_create_by_name" do
    it "should create document with name and period" do
      document = Scan::Document.find_or_create_by_name(@document_name, @period)
      document.should be_persisted
    end

    it "should find document with name and period" do
      document1 = Scan::Document.find_or_create_by_name(@document_name, @period)
      document2 = Scan::Document.find_or_create_by_name(@document_name, @period)
      document2.should eq(document1)
    end
  end
  
  it "should verify 'uniqueness_of_name' validation" do
    document = Scan::Document.find_or_create_by_name(@document_name, @period)
    document2 = Scan::Document.create(:name => @document_name, :period_id => @period.id)
    document.should be_persisted
    document2.should_not be_persisted
  end
  
  it "should hook update process for period after saved" do
    document = Scan::Document.new(:name => @document_name, :period_id => @period.id)
    document.pieces = 5
    document.sheets = 5
    document.pages = 20
    document.uploaded_pieces = 2
    document.uploaded_sheets = 2
    document.uploaded_pages = 14
    document.paperclips = 2
    document.oversized = 2
    document.save
    
    document2 = Scan::Document.new(:name => @document_name2, :period_id => @period.id)
    document2.pieces = 5
    document2.sheets = 5
    document2.pages = 20
    document2.uploaded_pieces = 2
    document2.uploaded_sheets = 2
    document2.uploaded_pages = 14
    document2.paperclips = 2
    document2.oversized = 2
    document2.save
    
    @period.reload
    @period.documents_name_tags.should eq(["b_XX y_#{Time.now.year} m_#{Time.now.month}","b_ZZ y_#{Time.now.year} m_#{Time.now.month}"])
    @period.pieces.should eq(10)
    @period.sheets.should eq(10)
    @period.pages.should eq(40)
    @period.uploaded_pieces.should eq(4)
    @period.uploaded_sheets.should eq(4)
    @period.uploaded_pages.should eq(28)
    @period.paperclips.should eq(4)
    @period.oversized.should eq(4)
  end

  it "#by_created_at" do
    document1 = FactoryGirl.create(Scan::Document, created_at: 2.seconds.ago, period_id: @period.id)
    document2 = FactoryGirl.create(Scan::Document, period_id: @period.id)
    results = Scan::Document.by_created_at.entries
    results.first.should eq(document2)
    results.last.should eq(document1)
  end
end
