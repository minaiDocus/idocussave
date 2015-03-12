# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Period do
  it "create one period" do
    period = Period.new
    period.should be_valid
    period.save
    period.should be_persisted
  end

  context 'when duration is 1' do
    it '#start_at should equal 2013-02-01 00:00:00' do
      period = Period.create(duration: 1, start_at: Time.local(2013, 2, 15))
      expect(period.start_at).to eq(Time.local(2013, 2, 1))
    end

    it '#end_at should equal 2013-02-30 23:59:59' do
      period = Period.create(duration: 1, start_at: Time.local(2013, 2, 15))
      expect(period.end_at).to eq(Time.local(2013, 2, 28, 23, 59, 59))
    end
  end

  context 'when duration is 3' do
    it '#start_at should equal 2013-04-01 00:00:00' do
      period = Period.create(duration: 3, start_at: Time.local(2013, 5, 15))
      expect(period.start_at).to eq(Time.local(2013, 4, 1))
    end

    it '#end_at should equal 2013-06-30 23:59:59' do
      period = Period.create(duration: 3, start_at: Time.local(2013, 5, 15))
      expect(period.end_at).to eq(Time.local(2013, 6, 30, 23, 59, 59))
    end
  end

  describe "should return right values" do
    subject(:period) {
      period = Period.new

      period.max_sheets_authorized = 5
      period.unit_price_of_excess_sheet = 12

      period.max_upload_pages_authorized = 15
      period.unit_price_of_excess_upload = 6

      period.max_dematbox_scan_pages_authorized = 15
      period.unit_price_of_excess_dematbox_scan = 6

      period.max_preseizure_pieces_authorized = 5
      period.unit_price_of_excess_preseizure = 12

      period.max_expense_pieces_authorized = 5
      period.unit_price_of_excess_expense = 12

      period.pieces = 30
      period.pages = 70
      period.scanned_pieces = 10
      period.scanned_sheets = 10
      period.scanned_pages = 20
      period.dematbox_scanned_pieces = 10
      period.dematbox_scanned_pages = 20
      period.uploaded_pieces = 10
      period.uploaded_pages = 30

      period.excess_preseizure_pieces = 5
      period.excess_expense_pieces = 5

      period.stub(:get_preseizure_pieces){ 10 }
      period.stub(:get_expense_pieces){ 10 }

      period
    }

    it { subject.excess_sheets.should eq(5) }
    it { subject.excess_uploaded_pages.should eq(15) }
    it { subject.excess_dematbox_scanned_pages.should eq(5) }
    it { subject.get_excess_preseizure_pieces.should eq(5) }
    it { subject.get_excess_expense_pieces.should eq(5) }

    it { subject.price_in_cents_of_excess_sheets.should eq(60) }
    it { subject.price_in_cents_of_excess_uploaded_pages.should eq(90) }
    it { subject.price_in_cents_of_excess_dematbox_scanned_pages.should eq(30) }
    it { subject.price_in_cents_of_excess_preseizures.should eq(60) }
    it { subject.price_in_cents_of_excess_expenses.should eq(60) }

    it { subject.price_in_cents_of_total_excess.should eq(300) }
  end

  describe ".period_name" do
    it 'should return 201301' do
      expect(Period.period_name 1, 0, Time.local(2013,1,1)).to eq('201301')
    end

    it 'should return 201212' do
      expect(Period.period_name 1, 1, Time.local(2013,1,1)).to eq('201212')
    end

    it 'should return 201211' do
      expect(Period.period_name 1, 2, Time.local(2013,1,1)).to eq('201211')
    end

    it 'should return 2013T1' do
      expect(Period.period_name 3, 0, Time.local(2013,1,1)).to eq('2013T1')
    end

    it 'should return 2012T4' do
      expect(Period.period_name 3, 1, Time.local(2013,1,1)).to eq('2012T4')
    end

    it 'should return 2012T3' do
      expect(Period.period_name 3, 2, Time.local(2013,1,1)).to eq('2012T3')
    end

    it 'should return 201402' do
      expect(Period.period_name 1, 2, Time.local(2014,4,1)).to eq('201402')
    end
  end
end
