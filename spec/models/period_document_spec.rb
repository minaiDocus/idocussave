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

  it "#by_created_at" do
    document1 = FactoryGirl.create(PeriodDocument, created_at: 2.seconds.ago, period_id: @period.id)
    document2 = FactoryGirl.create(PeriodDocument, period_id: @period.id)
    results = PeriodDocument.by_created_at.entries
    results.first.should eq(document2)
    results.last.should eq(document1)
  end
end
