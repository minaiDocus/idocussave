# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PeriodDocument do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  before(:each) do
    @period = Period.create!(:start_at => Time.now)
    @document_name = "TS0001 XX #{Time.now.strftime('%Y%m')} all"
    @document_name2 = "TS0001 ZZ #{Time.now.strftime('%Y%m')} all"
  end

  it "should create valid entry" do
    document = PeriodDocument.new(:name => @document_name)
    document.period = @period
    document.save
    document.should be_persisted
  end

  it "should find document named \"#{@document_name}\"" do
    document = PeriodDocument.new(:name => @document_name)
    document.period = @period
    document.save

    document2 = PeriodDocument.new(:name => "TS0001 XX #{(Time.now - 1.month).strftime('%Y%m')} all")
    document2.period = @period
    document2.save

    result = PeriodDocument.find_by_name(@document_name)
    result.should eq(document)
    result.should_not eq(document2)
  end

  describe ".find_or_create_by_name" do
    it "should create document with name and period" do
      document = PeriodDocument.find_or_create_by_name(@document_name, @period)
      document.should be_persisted
    end

    it "should find document with name and period" do
      document1 = PeriodDocument.find_or_create_by_name(@document_name, @period)
      document2 = PeriodDocument.find_or_create_by_name(@document_name, @period)
      document2.should eq(document1)
    end
  end

  it "should verify 'uniqueness_of_name' validation" do
    document = PeriodDocument.find_or_create_by_name(@document_name, @period)
    document2 = PeriodDocument.create(:name => @document_name, :period_id => @period.id)
    document.should be_persisted
    document2.should_not be_persisted
  end

  it "should hook update process for period after saved" do
    document = PeriodDocument.new(:name => @document_name, :period_id => @period.id)
    document.pieces = 20
    document.pages = 44
    document.uploaded_pieces = 2
    document.uploaded_pages = 8
    document.scanned_pieces = 8
    document.scanned_pages = 16
    document.scanned_sheets = 8
    document.dematbox_scanned_pieces = 10
    document.dematbox_scanned_pages = 20
    document.paperclips = 2
    document.oversized = 2
    document.save

    document2 = PeriodDocument.new(:name => @document_name2, :period_id => @period.id)
    document2.pieces = 17
    document2.pages = 39
    document2.uploaded_pieces = 4
    document2.uploaded_pages = 10
    document2.scanned_pieces = 10
    document2.scanned_pages = 20
    document2.scanned_sheets = 10
    document2.dematbox_scanned_pieces = 3
    document2.dematbox_scanned_pages = 9
    document2.paperclips = 2
    document2.oversized = 2
    document2.save

    @period.reload
    @period.documents_name_tags.should eq(["b_XX y_#{Time.now.year} m_#{Time.now.month}","b_ZZ y_#{Time.now.year} m_#{Time.now.month}"])
    @period.pieces.should eq(37)
    @period.pages.should eq(83)
    @period.uploaded_pieces.should eq(6)
    @period.uploaded_pages.should eq(18)
    @period.scanned_pieces.should eq(18)
    @period.scanned_pages.should eq(36)
    @period.scanned_sheets.should eq(18)
    @period.dematbox_scanned_pieces.should eq(13)
    @period.dematbox_scanned_pages.should eq(29)
    @period.paperclips.should eq(4)
    @period.oversized.should eq(4)
  end

  it "#by_created_at" do
    document1 = FactoryGirl.create(PeriodDocument, created_at: 2.seconds.ago, period_id: @period.id)
    document2 = FactoryGirl.create(PeriodDocument, period_id: @period.id)
    results = PeriodDocument.by_created_at.entries
    results.first.should eq(document2)
    results.last.should eq(document1)
  end
end
