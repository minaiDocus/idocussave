# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Period do
  it "create one period" do
    period = Period.new
    expect(period).to be_valid
    period.save
    expect(period).to be_persisted
  end

  context 'when duration is 1' do
    it '#start_at should equal 2013-02-01 00:00:00' do
      period = Period.create(duration: 1, start_at: Time.local(2013, 2, 15))
      expect(period.start_at).to eq(Time.local(2013, 2, 1))
    end

    it '#end_at should equal 2013-02-30 23:59:59' do
      period = Period.create(duration: 1, start_at: Time.local(2013, 2, 15))
      expect(period.end_at).to eq(Time.local(2013, 2).end_of_month)
    end
  end

  context 'when duration is 3' do
    it '#start_at should equal 2013-04-01 00:00:00' do
      period = Period.create(duration: 3, start_at: Time.local(2013, 5, 15))
      expect(period.start_at).to eq(Time.local(2013, 4, 1))
    end

    it '#end_at should equal 2013-06-30 23:59:59' do
      period = Period.create(duration: 3, start_at: Time.local(2013, 5, 15))
      expect(period.end_at).to eq(Time.local(2013, 6).end_of_month)
    end
  end

  describe "returns right values" do
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
      period.preseizure_pieces = 10
      period.expense_pieces = 10

      period
    }

    it { expect(subject.excess_sheets).to eq(5) }
    it { expect(subject.excess_uploaded_pages).to eq(15) }
    it { expect(subject.excess_dematbox_scanned_pages).to eq(5) }
    it { expect(subject.excess_preseizure_pieces).to eq(5) }
    it { expect(subject.excess_expense_pieces).to eq(5) }

    it { expect(subject.price_in_cents_of_excess_sheets).to eq(60) }
    it { expect(subject.price_in_cents_of_excess_uploaded_pages).to eq(90) }
    it { expect(subject.price_in_cents_of_excess_dematbox_scanned_pages).to eq(30) }
    it { expect(subject.price_in_cents_of_excess_preseizures).to eq(60) }
    it { expect(subject.price_in_cents_of_excess_expenses).to eq(60) }
  end

  describe ".period_name" do
    it 'returns 201301' do
      expect(Period.period_name 1, 0, Time.local(2013,1,1)).to eq('201301')
    end

    it 'returns 201212' do
      expect(Period.period_name 1, 1, Time.local(2013,1,1)).to eq('201212')
    end

    it 'returns 201211' do
      expect(Period.period_name 1, 2, Time.local(2013,1,1)).to eq('201211')
    end

    it 'returns 2013T1' do
      expect(Period.period_name 3, 0, Time.local(2013,1,1)).to eq('2013T1')
    end

    it 'returns 2012T4' do
      expect(Period.period_name 3, 1, Time.local(2013,1,1)).to eq('2012T4')
    end

    it 'returns 2012T3' do
      expect(Period.period_name 3, 2, Time.local(2013,1,1)).to eq('2012T3')
    end

    it 'returns 201402' do
      expect(Period.period_name 1, 2, Time.local(2014,4,1)).to eq('201402')
    end

    it 'returns 2015' do
      expect(Period.period_name 12, 0, Time.local(2015,1)).to eq('2015')
    end

    it 'returns 2014' do
      expect(Period.period_name 12, 1, Time.local(2015,1)).to eq('2014')
    end

    it 'returns 2013' do
      expect(Period.period_name 12, 2, Time.local(2015,1)).to eq('2013')
    end
  end
end
