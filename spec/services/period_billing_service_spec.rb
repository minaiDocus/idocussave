# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PeriodBillingService do
  describe '#amount_in_cents_wo_vat' do
    context 'for month' do
      before(:all) do
        period = Period.new
        period.duration = 1
        period.price_in_cents_wo_vat = 1000
        @period_billing_service = PeriodBillingService.new(period)
      end

      it 'with order 1 returns 1000' do
        amount = @period_billing_service.amount_in_cents_wo_vat(1)

        expect(amount).to eq(1000)
      end

      it 'with order 2 returns 0' do
        amount = @period_billing_service.amount_in_cents_wo_vat(2)

        expect(amount).to eq(1000)
      end
    end

    context 'for quarter' do
      context 'without billing' do
        before(:all) do
          period = Period.new
          period.duration = 3
          period.recurrent_products_price_in_cents_wo_vat = 300
          period.ponctual_products_price_in_cents_wo_vat  = 500
          period.excesses_price_in_cents_wo_vat           = 200
          period.price_in_cents_wo_vat                    = 1600
          @period_billing_service = PeriodBillingService.new(period)
        end

        it 'with order 1 returns 800' do
          amount = @period_billing_service.amount_in_cents_wo_vat(1)

          expect(amount).to eq(800)
        end

        it 'with order 2 returns 300' do
          amount = @period_billing_service.amount_in_cents_wo_vat(2)

          expect(amount).to eq(300)
        end

        it 'with order 3 returns 500' do
          amount = @period_billing_service.amount_in_cents_wo_vat(3)

          expect(amount).to eq(500)
        end
      end

      context 'with billing' do
        before(:all) do
          period = Period.new
          period.duration = 3
          period.recurrent_products_price_in_cents_wo_vat = 300
          period.ponctual_products_price_in_cents_wo_vat  = 500
          period.products_price_in_cents_wo_vat           = 1400
          period.excesses_price_in_cents_wo_vat           = 200
          period.price_in_cents_wo_vat                    = 1600
          billing = PeriodBilling.new
          billing.order = 1
          billing.amount_in_cents_wo_vat = 900
          period.billings << billing
          @period_billing_service = PeriodBillingService.new(period)
        end

        it 'with order 1 returns 900' do
          amount = @period_billing_service.amount_in_cents_wo_vat(1)

          expect(amount).to eq(900)
        end

        it 'with order 2 returns 250' do
          amount = @period_billing_service.amount_in_cents_wo_vat(2)

          expect(amount).to eq(250)
        end

        it 'with order 3 returns 450' do
          amount = @period_billing_service.amount_in_cents_wo_vat(3)

          expect(amount).to eq(450)
        end
      end
    end
  end

  describe '#save' do
    before(:each) do
      @period = Period.new
      @period.duration = 3
      @period.recurrent_products_price_in_cents_wo_vat = 300
      @period.ponctual_products_price_in_cents_wo_vat  = 500
      @period.excesses_price_in_cents_wo_vat           = 200
      @period.price_in_cents_wo_vat                    = 1600
      @period_billing_service = PeriodBillingService.new(@period)
    end

    after(:each) do
      @period.destroy
    end

    it 'with order 1 returns 800' do
      @period_billing_service.save(1)

      billing = @period.billings.first

      expect(@period.billings.size).to eq 1
      expect(billing).to be_persisted
      expect(billing.amount_in_cents_wo_vat).to eq(800)
    end

    it 'with order 2 returns 300' do
      @period_billing_service.save(2)

      billing = @period.billings.first

      expect(@period.billings.size).to eq 1
      expect(billing).to be_persisted
      expect(billing.amount_in_cents_wo_vat).to eq(300)
    end

    it 'with order 2 returns 500' do
      @period_billing_service.save(3)

      billing = @period.billings.first

      expect(@period.billings.size).to eq 1
      expect(billing).to be_persisted
      expect(billing.amount_in_cents_wo_vat).to eq(500)
    end
  end

  describe '#fill_past_with_0' do
    before(:each) do
      @period = Period.new
      @period.duration = 3
      @period.start_at = Time.local(2015,1,1)
      @period.end_at   = @period.start_at.end_of_quarter
      @period.recurrent_products_price_in_cents_wo_vat = 300
      @period.ponctual_products_price_in_cents_wo_vat  = 500
      @period.excesses_price_in_cents_wo_vat           = 200
      @period.price_in_cents_wo_vat                    = 1600
      @period_billing_service = PeriodBillingService.new(@period)
    end

    after(:each) do
      @period.destroy
    end

    it 'does not fill' do
      Timecop.freeze(2015,1,1)

      @period_billing_service.fill_past_with_0

      expect(@period.billings.size).to eq 0

      Timecop.return
    end

    it 'fills 1 billing' do
      Timecop.freeze(2015,2,1)

      @period_billing_service.fill_past_with_0
      billing = @period.billings.first

      expect(@period.billings.size).to eq 1
      expect(billing.order).to eq 1
      expect(billing.amount_in_cents_wo_vat).to eq 0

      Timecop.return
    end

    it 'fills 2 billings' do
      Timecop.freeze(2015,3,1)

      @period_billing_service.fill_past_with_0
      billing = @period.billings[0]
      billing2 = @period.billings[1]

      expect(@period.billings.size).to eq 2
      expect(billing.order).to eq 1
      expect(billing.amount_in_cents_wo_vat).to eq 0
      expect(billing2.order).to eq 2
      expect(billing2.amount_in_cents_wo_vat).to eq 0

      Timecop.return
    end
  end

  describe '.amount_in_cents_wo_vat' do
    before(:all) do
      period = Period.new
      period.duration = 1
      period.price_in_cents_wo_vat = 1500

      period2 = Period.new
      period2.duration = 3
      period2.recurrent_products_price_in_cents_wo_vat = 300
      period2.ponctual_products_price_in_cents_wo_vat  = 500
      period2.excesses_price_in_cents_wo_vat           = 200
      period2.price_in_cents_wo_vat                    = 1600

      @periods = [period, period2]
    end

    it 'with order 1 returns 1500 + 900' do
      amount = PeriodBillingService.amount_in_cents_wo_vat(1, @periods)

      expect(amount).to eq 2300
    end

    it 'with order 2 returns 1500 + 300' do
      amount = PeriodBillingService.amount_in_cents_wo_vat(2, @periods)

      expect(amount).to eq 1800
    end

    it 'with order 3 returns 1500 + 500' do
      amount = PeriodBillingService.amount_in_cents_wo_vat(3, @periods)

      expect(amount).to eq 2000
    end
  end

  describe '.order_of' do
    it 'returns 1' do
      result = PeriodBillingService.order_of(Time.local(2015,1,1))
      expect(result).to eq(1)

      result = PeriodBillingService.order_of(Time.local(2015,4,1))
      expect(result).to eq(1)

      result = PeriodBillingService.order_of(Time.local(2015,7,1))
      expect(result).to eq(1)

      result = PeriodBillingService.order_of(Time.local(2015,10,1))
      expect(result).to eq(1)
    end

    it 'returns 2' do
      result = PeriodBillingService.order_of(Time.local(2015,2,1))
      expect(result).to eq(2)

      result = PeriodBillingService.order_of(Time.local(2015,5,1))
      expect(result).to eq(2)

      result = PeriodBillingService.order_of(Time.local(2015,8,1))
      expect(result).to eq(2)

      result = PeriodBillingService.order_of(Time.local(2015,11,1))
      expect(result).to eq(2)
    end

    it 'returns 3' do
      result = PeriodBillingService.order_of(Time.local(2015,3,1))
      expect(result).to eq(3)

      result = PeriodBillingService.order_of(Time.local(2015,6,1))
      expect(result).to eq(3)

      result = PeriodBillingService.order_of(Time.local(2015,9,1))
      expect(result).to eq(3)

      result = PeriodBillingService.order_of(Time.local(2015,12,1))
      expect(result).to eq(3)
    end
  end

  describe '.vat_ratio' do
    it 'returns 1.196' do
      result = PeriodBillingService.vat_ratio(Time.local(2013,12,31))

      expect(result).to eq(1.196)
    end

    it 'returns 1.2' do
      result = PeriodBillingService.vat_ratio(Time.local(2014,1,1))

      expect(result).to eq(1.2)
    end
  end
end
