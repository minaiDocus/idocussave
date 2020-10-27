# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Billing::PeriodBilling do
  describe '#amount_in_cents_wo_vat' do
    context 'for month' do
      before(:all) do
        period = Period.new(start_date: Date.today)
        period.subscription = Subscription.create
        period.duration = 1
        period.price_in_cents_wo_vat = 1000
        period.save
        @period_billing_service = Billing::PeriodBilling.new(period)
      end

      it 'with order 1 returns 1000' do
        amount = @period_billing_service.amount_in_cents_wo_vat(1)

        expect(amount).to eq(1000)
      end

      it 'with order 2 returns 1000' do
        amount = @period_billing_service.amount_in_cents_wo_vat(2)

        expect(amount).to eq(1000)
      end
    end

    context 'for quarter' do
      context 'without billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.duration = 3
          period.recurrent_products_price_in_cents_wo_vat = 300
          period.ponctual_products_price_in_cents_wo_vat  = 500
          period.excesses_price_in_cents_wo_vat           = 200
          period.price_in_cents_wo_vat                    = 1600
          period.save
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'with order 1 returns 800' do
          amount = @period_billing_service.amount_in_cents_wo_vat(1)

          expect(amount).to eq(800)
        end

        it 'with order 4 returns 800' do
          amount = @period_billing_service.amount_in_cents_wo_vat(4)

          expect(amount).to eq(800)
        end

        it 'with order 2 returns 300' do
          amount = @period_billing_service.amount_in_cents_wo_vat(2)

          expect(amount).to eq(300)
        end

        it 'with order 5 returns 300' do
          amount = @period_billing_service.amount_in_cents_wo_vat(5)

          expect(amount).to eq(300)
        end

        it 'with order 3 returns 500' do
          amount = @period_billing_service.amount_in_cents_wo_vat(3)

          expect(amount).to eq(500)
        end

        it 'with order 6 returns 500' do
          amount = @period_billing_service.amount_in_cents_wo_vat(6)

          expect(amount).to eq(500)
        end
      end

      context 'with billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.duration = 3
          period.recurrent_products_price_in_cents_wo_vat = 300
          period.ponctual_products_price_in_cents_wo_vat  = 500
          period.products_price_in_cents_wo_vat           = 1400
          period.excesses_price_in_cents_wo_vat           = 200
          period.price_in_cents_wo_vat                    = 1600
          period.save
          billing = PeriodBilling.new
          billing.order = 1
          billing.amount_in_cents_wo_vat = 900
          period.billings << billing
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'with order 1 returns 900' do
          amount = @period_billing_service.amount_in_cents_wo_vat(1)

          expect(amount).to eq(900)
        end

        it 'with order 4 returns 900' do
          amount = @period_billing_service.amount_in_cents_wo_vat(4)

          expect(amount).to eq(900)
        end

        it 'with order 2 returns 250' do
          amount = @period_billing_service.amount_in_cents_wo_vat(2)

          expect(amount).to eq(250)
        end

        it 'with order 5 returns 250' do
          amount = @period_billing_service.amount_in_cents_wo_vat(5)

          expect(amount).to eq(250)
        end

        it 'with order 3 returns 450' do
          amount = @period_billing_service.amount_in_cents_wo_vat(3)

          expect(amount).to eq(450)
        end

        it 'with order 6 returns 450' do
          amount = @period_billing_service.amount_in_cents_wo_vat(6)

          expect(amount).to eq(450)
        end
      end
    end

    context 'for annual' do
      context 'without billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.duration = 12
          period.recurrent_products_price_in_cents_wo_vat = 19900
          period.excesses_price_in_cents_wo_vat           = 500
          period.products_price_in_cents_wo_vat           = 19900
          period.price_in_cents_wo_vat                    = 20400
          period.save
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'with order 1 returns 20400' do
          amount = @period_billing_service.amount_in_cents_wo_vat(1)

          expect(amount).to eq(20400)
        end

        it 'with order 2 returns 0' do
          amount = @period_billing_service.amount_in_cents_wo_vat(2)

          expect(amount).to eq(0)
        end
      end

      context 'with billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.duration = 12
          period.recurrent_products_price_in_cents_wo_vat = 19900
          period.products_price_in_cents_wo_vat           = 19900
          period.excesses_price_in_cents_wo_vat           = 500
          period.price_in_cents_wo_vat                    = 20400
          period.save
          billing = PeriodBilling.new
          billing.order = 1
          billing.amount_in_cents_wo_vat = 20000
          period.billings << billing
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'with order 1 returns 20000' do
          amount = @period_billing_service.amount_in_cents_wo_vat(1)

          expect(amount).to eq(20000)
        end

        it 'with order 2 returns 400' do
          amount = @period_billing_service.amount_in_cents_wo_vat(2)

          expect(amount).to eq(400)
        end

        it 'with order 3 returns 0' do
          amount = @period_billing_service.amount_in_cents_wo_vat(3)

          expect(amount).to eq(0)
        end
      end
    end
  end

  describe '#data' do
    context 'for month' do
      before(:all) do
        period = Period.new(start_date: Date.today)
        period.subscription = Subscription.create
        period.duration = 1
        period.oversized = 1
        period.save
        @period_billing_service = Billing::PeriodBilling.new(period)
      end

      it 'returns 1' do
        oversized = @period_billing_service.data(:oversized, 1)

        expect(oversized).to eq(1)
      end

      it 'returns 1' do
        oversized = @period_billing_service.data(:oversized, 2)

        expect(oversized).to eq(1)
      end
    end

    context 'for quarter' do
      context 'without billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.subscription = Subscription.create
          period.duration = 3
          period.oversized = 1
          period.save
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'with order 1 returns 0' do
          oversized = @period_billing_service.data(:oversized, 1)

          expect(oversized).to eq(0)
        end

        it 'with order 4 returns 0' do
          oversized = @period_billing_service.data(:oversized, 4)

          expect(oversized).to eq(0)
        end

        it 'with order 2 returns 0' do
          oversized = @period_billing_service.data(:oversized, 2)

          expect(oversized).to eq(0)
        end

        it 'with order 5 returns 0' do
          oversized = @period_billing_service.data(:oversized, 5)

          expect(oversized).to eq(0)
        end

        it 'with order 3 returns 1' do
          oversized = @period_billing_service.data(:oversized, 3)

          expect(oversized).to eq(1)
        end

        it 'with order 6 returns 1' do
          oversized = @period_billing_service.data(:oversized, 6)

          expect(oversized).to eq(1)
        end
      end

      context 'with billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.subscription = Subscription.create
          period.duration = 3
          period.oversized = 5
          period.save
          billing = PeriodBilling.new
          billing.order = 1
          billing.oversized = 1
          period.billings << billing
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'with order 1 returns 0' do
          oversized = @period_billing_service.data(:oversized, 1)

          expect(oversized).to eq(0)
        end

        it 'with order 4 returns 0' do
          oversized = @period_billing_service.data(:oversized, 4)

          expect(oversized).to eq(0)
        end

        it 'with order 2 returns 0' do
          oversized = @period_billing_service.data(:oversized, 2)

          expect(oversized).to eq(0)
        end

        it 'with order 5 returns 0' do
          oversized = @period_billing_service.data(:oversized, 5)

          expect(oversized).to eq(0)
        end

        it 'with order 3 returns 5' do
          oversized = @period_billing_service.data(:oversized, 3)

          expect(oversized).to eq(5)
        end

        it 'with order 6 returns 5' do
          oversized = @period_billing_service.data(:oversized, 6)

          expect(oversized).to eq(5)
        end
      end
    end

    context 'for annual' do
      context 'without billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.subscription = Subscription.create
          period.duration = 12
          period.oversized = 1
          period.save
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'returns 1' do
          oversized = @period_billing_service.data(:oversized, 1)

          expect(oversized).to eq(1)
        end

        it 'returns 0' do
          oversized = @period_billing_service.data(:oversized, 2)

          expect(oversized).to eq(0)
        end
      end

      context 'with billing' do
        before(:all) do
          period = Period.new(start_date: Date.today)
          period.subscription = Subscription.create
          period.duration = 12
          period.oversized = 5
          period.save
          billing = PeriodBilling.new
          billing.order = 1
          billing.oversized = 1
          period.billings << billing
          @period_billing_service = Billing::PeriodBilling.new(period)
        end

        it 'returns 1' do
          oversized = @period_billing_service.data(:oversized, 1)

          expect(oversized).to eq(1)
        end

        it 'returns 4' do
          oversized = @period_billing_service.data(:oversized, 2)

          expect(oversized).to eq(4)
        end

        it 'returns 0' do
          oversized = @period_billing_service.data(:oversized, 3)

          expect(oversized).to eq(0)
        end
      end
    end
  end

  describe '#next_order' do
    it 'returns 1' do
      period = Period.new(start_date: Date.today)
      period.duration = 3
      period.save
      period_billing_service = Billing::PeriodBilling.new(period)
      order = period_billing_service.next_order

      expect(order).to eq(1)
    end

    it 'returns 3' do
      period = Period.new(start_date: Date.today)
      period.duration = 3
      period.save
      billing = PeriodBilling.new(order: 2)
      period.billings << billing
      period_billing_service = Billing::PeriodBilling.new(period)
      order = period_billing_service.next_order

      expect(order).to eq(3)
    end
  end

  describe '#save' do
    context 'for quarter' do
      before(:each) do
        @period = Period.new(start_date: Date.today)
        @period.subscription = Subscription.create
        @period.duration = 3
        @period.recurrent_products_price_in_cents_wo_vat = 300
        @period.ponctual_products_price_in_cents_wo_vat  = 500
        @period.excesses_price_in_cents_wo_vat           = 780
        @period.price_in_cents_wo_vat                    = 2180
        @period.scanned_pieces                           = 100
        @period.scanned_sheets                           = 110
        @period.scanned_pages                            = 220
        @period.dematbox_scanned_pieces                  = 120
        @period.dematbox_scanned_pages                   = 240
        @period.uploaded_pieces                          = 115
        @period.uploaded_pages                           = 250
        @period.retrieved_pieces                         = 100
        @period.retrieved_pages                          = 200
        @period.preseizure_pieces                        = 110
        @period.expense_pieces                           = 0
        @period.paperclips                               = 5
        @period.oversized                                = 4
        @period.save
        @period_billing_service = Billing::PeriodBilling.new(@period)
      end

      after(:each) do
        @period.destroy
      end

      it 'with order 1 returns 800' do
        @period_billing_service.save(1)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(1)
        expect(billing.amount_in_cents_wo_vat).to eq(800)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(0)
        expect(billing.scanned_pieces).to eq(0)
        expect(billing.scanned_sheets).to eq(0)
        expect(billing.scanned_pages).to eq(0)
        expect(billing.dematbox_scanned_pieces).to eq(0)
        expect(billing.dematbox_scanned_pages).to eq(0)
        expect(billing.uploaded_pieces).to eq(0)
        expect(billing.uploaded_pages).to eq(0)
        expect(billing.retrieved_pieces).to eq(0)
        expect(billing.retrieved_pages).to eq(0)
        expect(billing.preseizure_pieces).to eq(0)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(0)
        expect(billing.oversized).to eq(0)
        expect(billing.excess_sheets).to eq(0)
        expect(billing.excess_uploaded_pages).to eq(0)
        expect(billing.excess_dematbox_scanned_pages).to eq(0)
        expect(billing.excess_compta_pieces).to eq(0)
      end

      it 'with order 4 returns 800' do
        @period_billing_service.save(4)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(1)
        expect(billing.amount_in_cents_wo_vat).to eq(800)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(0)
        expect(billing.scanned_pieces).to eq(0)
        expect(billing.scanned_sheets).to eq(0)
        expect(billing.scanned_pages).to eq(0)
        expect(billing.dematbox_scanned_pieces).to eq(0)
        expect(billing.dematbox_scanned_pages).to eq(0)
        expect(billing.uploaded_pieces).to eq(0)
        expect(billing.uploaded_pages).to eq(0)
        expect(billing.retrieved_pieces).to eq(0)
        expect(billing.retrieved_pages).to eq(0)
        expect(billing.preseizure_pieces).to eq(0)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(0)
        expect(billing.oversized).to eq(0)
        expect(billing.excess_sheets).to eq(0)
        expect(billing.excess_uploaded_pages).to eq(0)
        expect(billing.excess_dematbox_scanned_pages).to eq(0)
        expect(billing.excess_compta_pieces).to eq(0)
      end

      it 'with order 2 returns 300' do
        @period_billing_service.save(2)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(2)
        expect(billing.amount_in_cents_wo_vat).to eq(300)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(0)
        expect(billing.scanned_pieces).to eq(0)
        expect(billing.scanned_sheets).to eq(0)
        expect(billing.scanned_pages).to eq(0)
        expect(billing.dematbox_scanned_pieces).to eq(0)
        expect(billing.dematbox_scanned_pages).to eq(0)
        expect(billing.uploaded_pieces).to eq(0)
        expect(billing.uploaded_pages).to eq(0)
        expect(billing.retrieved_pieces).to eq(0)
        expect(billing.retrieved_pages).to eq(0)
        expect(billing.preseizure_pieces).to eq(0)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(0)
        expect(billing.oversized).to eq(0)
        expect(billing.excess_sheets).to eq(0)
        expect(billing.excess_uploaded_pages).to eq(0)
        expect(billing.excess_dematbox_scanned_pages).to eq(0)
        expect(billing.excess_compta_pieces).to eq(0)
      end

      it 'with order 5 returns 300' do
        @period_billing_service.save(5)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(2)
        expect(billing.amount_in_cents_wo_vat).to eq(300)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(0)
        expect(billing.scanned_pieces).to eq(0)
        expect(billing.scanned_sheets).to eq(0)
        expect(billing.scanned_pages).to eq(0)
        expect(billing.dematbox_scanned_pieces).to eq(0)
        expect(billing.dematbox_scanned_pages).to eq(0)
        expect(billing.uploaded_pieces).to eq(0)
        expect(billing.uploaded_pages).to eq(0)
        expect(billing.retrieved_pieces).to eq(0)
        expect(billing.retrieved_pages).to eq(0)
        expect(billing.preseizure_pieces).to eq(0)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(0)
        expect(billing.oversized).to eq(0)
        expect(billing.excess_sheets).to eq(0)
        expect(billing.excess_uploaded_pages).to eq(0)
        expect(billing.excess_dematbox_scanned_pages).to eq(0)
        expect(billing.excess_compta_pieces).to eq(0)
      end

      it 'with order 3 returns 1080' do
        @period_billing_service.save(3)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(3)
        expect(billing.amount_in_cents_wo_vat).to eq(1080)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(780)
        expect(billing.scanned_pieces).to eq(100)
        expect(billing.scanned_sheets).to eq(110)
        expect(billing.scanned_pages).to eq(220)
        expect(billing.dematbox_scanned_pieces).to eq(120)
        expect(billing.dematbox_scanned_pages).to eq(240)
        expect(billing.uploaded_pieces).to eq(115)
        expect(billing.uploaded_pages).to eq(250)
        expect(billing.retrieved_pieces).to eq(100)
        expect(billing.retrieved_pages).to eq(200)
        expect(billing.preseizure_pieces).to eq(110)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(5)
        expect(billing.oversized).to eq(4)
        expect(billing.excess_sheets).to eq(10)
        expect(billing.excess_uploaded_pages).to eq(50)
        expect(billing.excess_dematbox_scanned_pages).to eq(40)
        expect(billing.excess_compta_pieces).to eq(10)
      end

      it 'with order 6 returns 1080' do
        @period_billing_service.save(6)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(3)
        expect(billing.amount_in_cents_wo_vat).to eq(1080)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(780)
        expect(billing.scanned_pieces).to eq(100)
        expect(billing.scanned_sheets).to eq(110)
        expect(billing.scanned_pages).to eq(220)
        expect(billing.dematbox_scanned_pieces).to eq(120)
        expect(billing.dematbox_scanned_pages).to eq(240)
        expect(billing.uploaded_pieces).to eq(115)
        expect(billing.uploaded_pages).to eq(250)
        expect(billing.retrieved_pieces).to eq(100)
        expect(billing.retrieved_pages).to eq(200)
        expect(billing.preseizure_pieces).to eq(110)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(5)
        expect(billing.oversized).to eq(4)
        expect(billing.excess_sheets).to eq(10)
        expect(billing.excess_uploaded_pages).to eq(50)
        expect(billing.excess_dematbox_scanned_pages).to eq(40)
        expect(billing.excess_compta_pieces).to eq(10)
      end
    end

    context 'for annual' do
      before(:each) do
        @period = Period.new(start_date: Date.today)
        @period.subscription = Subscription.create
        @period.duration = 12
        @period.recurrent_products_price_in_cents_wo_vat = 19900
        @period.excesses_price_in_cents_wo_vat           = 780
        @period.price_in_cents_wo_vat                    = 20680
        @period.scanned_pieces                           = 100
        @period.scanned_sheets                           = 110
        @period.scanned_pages                            = 220
        @period.dematbox_scanned_pieces                  = 120
        @period.dematbox_scanned_pages                   = 240
        @period.uploaded_pieces                          = 115
        @period.uploaded_pages                           = 250
        @period.retrieved_pieces                         = 100
        @period.retrieved_pages                          = 200
        @period.preseizure_pieces                        = 110
        @period.expense_pieces                           = 0
        @period.paperclips                               = 5
        @period.oversized                                = 4
        @period.save
        @period_billing_service = Billing::PeriodBilling.new(@period)
      end

      after(:each) do
        @period.destroy
      end

      it 'with order 1 returns 20680' do
        @period_billing_service.save(1)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(1)
        expect(billing.amount_in_cents_wo_vat).to eq(20680)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(780)
        expect(billing.scanned_pieces).to eq(100)
        expect(billing.scanned_sheets).to eq(110)
        expect(billing.scanned_pages).to eq(220)
        expect(billing.dematbox_scanned_pieces).to eq(120)
        expect(billing.dematbox_scanned_pages).to eq(240)
        expect(billing.uploaded_pieces).to eq(115)
        expect(billing.uploaded_pages).to eq(250)
        expect(billing.retrieved_pieces).to eq(100)
        expect(billing.retrieved_pages).to eq(200)
        expect(billing.preseizure_pieces).to eq(110)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(5)
        expect(billing.oversized).to eq(4)
        expect(billing.excess_sheets).to eq(10)
        expect(billing.excess_uploaded_pages).to eq(50)
        expect(billing.excess_dematbox_scanned_pages).to eq(40)
        expect(billing.excess_compta_pieces).to eq(10)
      end

      it 'with order 2 returns 0' do
        @period_billing_service.save(2)

        billing = @period.billings.first

        expect(@period.billings.size).to eq 1
        expect(billing).to be_persisted
        expect(billing.order).to eq(2)
        expect(billing.amount_in_cents_wo_vat).to eq(0)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(0)
        expect(billing.scanned_pieces).to eq(0)
        expect(billing.scanned_sheets).to eq(0)
        expect(billing.scanned_pages).to eq(0)
        expect(billing.dematbox_scanned_pieces).to eq(0)
        expect(billing.dematbox_scanned_pages).to eq(0)
        expect(billing.uploaded_pieces).to eq(0)
        expect(billing.uploaded_pages).to eq(0)
        expect(billing.retrieved_pieces).to eq(0)
        expect(billing.retrieved_pages).to eq(0)
        expect(billing.preseizure_pieces).to eq(0)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(0)
        expect(billing.oversized).to eq(0)
        expect(billing.excess_sheets).to eq(0)
        expect(billing.excess_uploaded_pages).to eq(0)
        expect(billing.excess_dematbox_scanned_pages).to eq(0)
        expect(billing.excess_compta_pieces).to eq(0)
      end

      it 'returns 20680/0/0/120' do
        3.times.each do |i|
          @period_billing_service.save(i+1)
        end
        @period.scanned_sheets = 120
        @period.excesses_price_in_cents_wo_vat = 900
        @period.price_in_cents_wo_vat = 20800
        @period.save
        @period_billing_service.save(4)

        expect(@period.billings.size).to eq 4

        billing = @period.billings.where(order: 1).first
        expect(billing).to be_persisted
        expect(billing.order).to eq(1)
        expect(billing.scanned_sheets).to eq(110)
        expect(billing.amount_in_cents_wo_vat).to eq(20680)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(780)

        2.times do |i|
          billing = @period.billings.where(order: i+2).first
          expect(billing).to be_persisted
          expect(billing.order).to eq(i+2)
          expect(billing.scanned_sheets).to eq(0)
          expect(billing.amount_in_cents_wo_vat).to eq(0)
          expect(billing.excesses_amount_in_cents_wo_vat).to eq(0)
        end

        billing = @period.billings.where(order: 4).first
        expect(billing).to be_persisted
        expect(billing.order).to eq(4)
        expect(billing.amount_in_cents_wo_vat).to eq(120)
        expect(billing.excesses_amount_in_cents_wo_vat).to eq(120)
        expect(billing.scanned_pieces).to eq(0)
        expect(billing.scanned_sheets).to eq(10)
        expect(billing.scanned_pages).to eq(0)
        expect(billing.dematbox_scanned_pieces).to eq(0)
        expect(billing.dematbox_scanned_pages).to eq(0)
        expect(billing.uploaded_pieces).to eq(0)
        expect(billing.uploaded_pages).to eq(0)
        expect(billing.retrieved_pieces).to eq(0)
        expect(billing.retrieved_pages).to eq(0)
        expect(billing.preseizure_pieces).to eq(0)
        expect(billing.expense_pieces).to eq(0)
        expect(billing.paperclips).to eq(0)
        expect(billing.oversized).to eq(0)
        expect(billing.excess_sheets).to eq(10)
        expect(billing.excess_uploaded_pages).to eq(0)
        expect(billing.excess_dematbox_scanned_pages).to eq(0)
        expect(billing.excess_compta_pieces).to eq(0)
      end
    end
  end

  describe '#fill_past_with_0' do
    context 'for month' do
      before(:each) do
        @period = Period.new
        @period.duration = 1
        @period.start_date = Time.local(2015,1,1).to_date
        @period.save
        @period_billing_service = Billing::PeriodBilling.new(@period)
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
    end

    context 'for quarter' do
      before(:each) do
        @period = Period.new
        @period.duration = 3
        @period.start_date = Time.local(2015,1,1).to_date
        @period.save
        @period_billing_service = Billing::PeriodBilling.new(@period)
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
        expect(billing).to be_persisted
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
        expect(billing).to be_persisted
        expect(billing.order).to eq 1
        expect(billing.amount_in_cents_wo_vat).to eq 0
        expect(billing2).to be_persisted
        expect(billing2.order).to eq 2
        expect(billing2.amount_in_cents_wo_vat).to eq 0

        Timecop.return
      end
    end

    context 'for annual' do
      before(:each) do
        @period = Period.new
        @period.duration = 12
        @period.start_date = Time.local(2015,1,1).to_date
        @period.save
        @period_billing_service = Billing::PeriodBilling.new(@period)
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
        expect(billing).to be_persisted
        expect(billing.order).to eq 1
        expect(billing.amount_in_cents_wo_vat).to eq 0

        Timecop.return
      end

      it 'fills 3 billings' do
        Timecop.freeze(2015,4,1)

        @period_billing_service.fill_past_with_0
        billing = @period.billings[0]
        billing2 = @period.billings[1]
        billing3 = @period.billings[2]

        expect(@period.billings.size).to eq 3
        expect(billing).to be_persisted
        expect(billing.order).to eq 1
        expect(billing.amount_in_cents_wo_vat).to eq 0
        expect(billing2).to be_persisted
        expect(billing2.order).to eq 2
        expect(billing2.amount_in_cents_wo_vat).to eq 0
        expect(billing3).to be_persisted
        expect(billing3.order).to eq 3
        expect(billing3.amount_in_cents_wo_vat).to eq 0

        Timecop.return
      end
    end
  end

  describe '#fill_with_0' do
    before(:each) do
      @period = Period.new
      @period.duration = 3
      @period.start_date = Time.local(2015,1,1).to_date
      @period.save
      @period_billing_service = Billing::PeriodBilling.new(@period)
    end

    after(:each) do
      @period.destroy
    end

    it 'fills 1 billing' do
      @period_billing_service.fill_with_0(2)
      billing = @period.billings.first

      expect(@period.billings.size).to eq 1
      expect(billing).to be_persisted
      expect(billing.order).to eq 2
      expect(billing.amount_in_cents_wo_vat).to eq 0
    end
  end

  describe '.amount_in_cents_wo_vat' do
    before(:all) do
      period = Period.new(start_date: Date.today)
      period.duration = 1
      period.price_in_cents_wo_vat = 1500
      period.save

      period2 = Period.new(start_date: Date.today)
      period2.duration = 3
      period2.recurrent_products_price_in_cents_wo_vat = 300
      period2.ponctual_products_price_in_cents_wo_vat  = 500
      period2.excesses_price_in_cents_wo_vat           = 200
      period2.price_in_cents_wo_vat                    = 1600
      period2.save

      period3 = Period.new(start_date: Date.today)
      period3.duration = 12
      period3.recurrent_products_price_in_cents_wo_vat = 19900
      period3.ponctual_products_price_in_cents_wo_vat  = 0
      period3.excesses_price_in_cents_wo_vat           = 500
      period3.price_in_cents_wo_vat                    = 20400
      period3.save
      period3.billings << PeriodBilling.new(order: 1, amount_in_cents_wo_vat: 20000)

      @periods = [period, period2, period3]
    end

    it 'with order 1 returns 1500 + 900 + 20000' do
      amount = Billing::PeriodBilling.amount_in_cents_wo_vat(1, @periods)

      expect(amount).to eq 22300
    end

    it 'with order 2 returns 1500 + 300 + 400' do
      amount = Billing::PeriodBilling.amount_in_cents_wo_vat(2, @periods)

      expect(amount).to eq 2200
    end

    it 'with order 3 returns 1500 + 500 + 0' do
      amount = Billing::PeriodBilling.amount_in_cents_wo_vat(3, @periods)

      expect(amount).to eq 2000
    end
  end

  describe '.quarter_order_of' do
    it 'returns 1' do
      result = Billing::PeriodBilling.quarter_order_of(1)
      expect(result).to eq(1)

      result = Billing::PeriodBilling.quarter_order_of(4)
      expect(result).to eq(1)

      result = Billing::PeriodBilling.quarter_order_of(7)
      expect(result).to eq(1)

      result = Billing::PeriodBilling.quarter_order_of(10)
      expect(result).to eq(1)
    end

    it 'returns 2' do
      result = Billing::PeriodBilling.quarter_order_of(2)
      expect(result).to eq(2)

      result = Billing::PeriodBilling.quarter_order_of(5)
      expect(result).to eq(2)

      result = Billing::PeriodBilling.quarter_order_of(8)
      expect(result).to eq(2)

      result = Billing::PeriodBilling.quarter_order_of(11)
      expect(result).to eq(2)
    end

    it 'returns 3' do
      result = Billing::PeriodBilling.quarter_order_of(3)
      expect(result).to eq(3)

      result = Billing::PeriodBilling.quarter_order_of(6)
      expect(result).to eq(3)

      result = Billing::PeriodBilling.quarter_order_of(9)
      expect(result).to eq(3)

      result = Billing::PeriodBilling.quarter_order_of(12)
      expect(result).to eq(3)
    end
  end

  describe '.vat_ratio' do
    it 'returns 1.196' do
      result = Billing::PeriodBilling.vat_ratio(Time.local(2013,12,31))

      expect(result).to eq(1.196)
    end

    it 'returns 1.2' do
      result = Billing::PeriodBilling.vat_ratio(Time.local(2014,1,1))

      expect(result).to eq(1.2)
    end
  end
end
