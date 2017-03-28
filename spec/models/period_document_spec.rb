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
    @period = Period.create!(:start_date => Date.today)
    @document_name = "TS0001 XX #{Time.now.strftime('%Y%m')} all"
    @document_name2 = "TS0001 ZZ #{Time.now.strftime('%Y%m')} all"
  end

  it "should create valid entry" do
    document = PeriodDocument.new(:name => @document_name)
    document.period = @period
    document.save
    expect(document).to be_persisted
  end

  it "should find document named \"#{@document_name}\"" do
    document = PeriodDocument.new(:name => @document_name)
    document.period = @period
    document.save

    document2 = PeriodDocument.new(:name => "TS0001 XX #{(Time.now - 1.month).strftime('%Y%m')} all")
    document2.period = @period
    document2.save

    result = PeriodDocument.find_by_name(@document_name)
    expect(result).to eq(document)
    expect(result).not_to eq(document2)
  end

  describe ".find_or_create_by_name" do
    it "should create document with name and period" do
      document = PeriodDocument.find_or_create_by_name(@document_name, @period)
      expect(document).to be_persisted
    end

    it "should find document with name and period" do
      document1 = PeriodDocument.find_or_create_by_name(@document_name, @period)
      document2 = PeriodDocument.find_or_create_by_name(@document_name, @period)
      expect(document2).to eq(document1)
    end
  end

  it "should verify 'uniqueness_of_name' validation" do
    document = PeriodDocument.find_or_create_by_name(@document_name, @period)
    document2 = PeriodDocument.create(:name => @document_name, :period_id => @period.id)
    expect(document).to be_persisted
    expect(document2).not_to be_persisted
  end
end
