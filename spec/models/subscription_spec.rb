# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Subscription do
  before(:all) do
    @user = FactoryBot.create(:user)
    @subscription = Subscription.create(user_id: @user.id)
  end

  it 'is persisted' do
    expect(@subscription).to be_persisted
  end

  it 'have default values' do
    expect(@subscription.period_duration).to eq 1
    expect(@subscription.tva_ratio).to eq 1.2
    expect(@subscription.max_sheets_authorized).to eq 100
    expect(@subscription.max_upload_pages_authorized).to eq 200
    expect(@subscription.max_dematbox_scan_pages_authorized).to eq 200
    expect(@subscription.max_preseizure_pieces_authorized).to eq 100
    expect(@subscription.max_expense_pieces_authorized).to eq 100
    expect(@subscription.max_paperclips_authorized).to eq 0
    expect(@subscription.max_oversized_authorized).to eq 0
    expect(@subscription.unit_price_of_excess_sheet).to eq 12
    expect(@subscription.unit_price_of_excess_preseizure).to eq 12
    expect(@subscription.unit_price_of_excess_expense).to eq 12
    expect(@subscription.unit_price_of_excess_paperclips).to eq 20
    expect(@subscription.unit_price_of_excess_oversized).to eq 100
    expect(@subscription.unit_price_of_excess_upload).to eq 6
    expect(@subscription.unit_price_of_excess_dematbox_scan).to eq 6
  end

  describe '#find_period' do
    context 'monthly' do
      before(:all) do
        @period = Period.new
        @period.start_date   = Date.parse('2015-01-01')
        @period.duration     = 1
        @period.subscription = @subscription
        @period.save
      end

      after(:all) do
        Period.destroy_all
      end

      it 'returns nothing for 2014-12' do
        period = @subscription.find_period(Date.parse('2014-12-01'))

        expect(period).to be_nil
      end

      it 'returns nothing for 2015-02' do
        period = @subscription.find_period(Date.parse('2015-02-01'))

        expect(period).to be_nil
      end

      it 'returns period for 2015-01' do
        period = @subscription.find_period(Date.parse('2015-01-01'))

        expect(period).to eq @period
      end
    end

    context 'annually' do
      before(:all) do
        @period = Period.new
        @period.start_date   = Date.parse('2015-01-01')
        @period.duration     = 12
        @period.subscription = @subscription
        @period.save
      end

      after(:all) do
        Period.destroy_all
      end

      it 'returns nothing for 2014-12' do
        period = @subscription.find_period(Date.parse('2014-12-01'))

        expect(period).to be_nil
      end

      it 'returns nothing for 2016-01' do
        period = @subscription.find_period(Date.parse('2016-01-01'))

        expect(period).to be_nil
      end

      it 'returns period for 2015-01' do
        period = @subscription.find_period(Date.parse('2015-01-01'))

        expect(period).to eq @period
      end

      it 'returns period for 2015-12' do
        period = @subscription.find_period(Date.parse('2015-12-01'))

        expect(period).to eq @period
      end
    end
  end

  describe '#create_period' do
    before(:all) do
      @subscription.periods = []
    end

    after(:all) do
      Period.destroy_all
    end

    it 'returns a period' do
      expect(@subscription.periods).to be_empty

      period = @subscription.create_period(Date.parse('2015-01-01'))

      expect(period).to be_persisted
      expect(period.start_date).to eq Date.parse('2015-01-01')
      expect(@subscription.periods).to eq [period]
    end
  end
end
