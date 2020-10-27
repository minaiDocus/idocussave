# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Billing::UpdatePeriodPrice do
  before(:all) do
    @user = FactoryBot.create(:user)
    @subscription = Subscription.create(user_id: @user.id)
  end

  it 'have default values' do
    period = Period.create(subscription: @subscription, start_date: Date.today.beginning_of_month)

    Billing::UpdatePeriodPrice.new(period).execute

    expect(period.recurrent_products_price_in_cents_wo_vat).to eq 0
    expect(period.ponctual_products_price_in_cents_wo_vat).to eq 0
    expect(period.products_price_in_cents_wo_vat).to eq 0
    expect(period.excesses_price_in_cents_wo_vat).to eq 0
    expect(period.price_in_cents_wo_vat).to eq 0
  end

  context 'as customer' do
    context 'for monthly' do
      it 'set values' do
        allow_any_instance_of(Period).to receive(:is_valid_for_quota_organization).and_return(false)
        period = Period.new
        period.user = @user
        period.subscription = @subscription
        period.duration = 1
        period.start_date = Date.today.beginning_of_month
        period.save
        option1 = ProductOptionOrder.new(name: 'Recurrent option', price_in_cents_wo_vat: 1000, duration: 0, group_position: 1)
        option2 = ProductOptionOrder.new(name: 'Ponctual option',  price_in_cents_wo_vat: 2000, duration: 1, group_position: 2)
        period.product_option_orders << option1
        period.product_option_orders << option2
        period.scanned_sheets = 101 # excesses : 1, price : 12 cents
        period.uploaded_pages = 202 # excesses : 2, price : 12 cents
        period.dematbox_scanned_pages = 203 # excesses : 3, price : 18 cents
        period.preseizure_pieces = 104 # excesses : 4, price : 48 cents
        period.expense_pieces = 105 # excesses : 5, price : 60 cents
        period.save

        Billing::UpdatePeriodPrice.new(period).execute

        expect(period.recurrent_products_price_in_cents_wo_vat).to eq 1000
        expect(period.ponctual_products_price_in_cents_wo_vat).to eq 2000
        expect(period.products_price_in_cents_wo_vat).to eq 3000
        expect(period.excesses_price_in_cents_wo_vat).to eq 150
        expect(period.price_in_cents_wo_vat).to eq 3150
      end
    end

    context 'for quarterly' do
      it 'set values' do
        period = Period.new
        period.user = @user
        period.subscription = @subscription
        period.duration = 3
        period.start_date = Date.today.beginning_of_quarter
        period.save
        option1 = ProductOptionOrder.new(name: 'Recurrent option', price_in_cents_wo_vat: 900,  duration: 0, group_position: 1)
        option2 = ProductOptionOrder.new(name: 'Ponctual option',  price_in_cents_wo_vat: 1500, duration: 1, group_position: 2)
        period.product_option_orders << option1
        period.product_option_orders << option2
        period.scanned_sheets = 101 # excesses : 1, price : 12 cents
        period.uploaded_pages = 202 # excesses : 2, price : 12 cents
        period.dematbox_scanned_pages = 203 # excesses : 3, price : 18 cents
        period.preseizure_pieces = 104 # excesses : 4, price : 48 cents
        period.expense_pieces = 105 # excesses : 5, price : 60 cents
        period.save

        Billing::UpdatePeriodPrice.new(period).execute

        expect(period.recurrent_products_price_in_cents_wo_vat).to eq 300
        expect(period.ponctual_products_price_in_cents_wo_vat).to eq 1500
        expect(period.products_price_in_cents_wo_vat).to eq 2400
        expect(period.excesses_price_in_cents_wo_vat).to eq 150
        expect(period.price_in_cents_wo_vat).to eq 2550
      end
    end

    context 'for annually' do
      it 'set values' do
        period = Period.new
        period.user = @user
        period.subscription = @subscription
        period.duration = 12
        period.start_date = Date.today.beginning_of_year
        period.save
        option = ProductOptionOrder.new(name: 'Recurrent option', price_in_cents_wo_vat: 19900, duration: 0, group_position: 1)
        period.product_option_orders << option
        period.scanned_sheets = 101 # excesses : 1, price : 12 cents
        period.uploaded_pages = 202 # excesses : 2, price : 12 cents
        period.dematbox_scanned_pages = 203 # excesses : 3, price : 18 cents
        period.preseizure_pieces = 104 # excesses : 4, price : 48 cents
        period.expense_pieces = 105 # excesses : 5, price : 60 cents
        period.save

        Billing::UpdatePeriodPrice.new(period).execute

        expect(period.recurrent_products_price_in_cents_wo_vat).to eq 19900
        expect(period.ponctual_products_price_in_cents_wo_vat).to eq 0
        expect(period.products_price_in_cents_wo_vat).to eq 19900
        expect(period.excesses_price_in_cents_wo_vat).to eq 150
        expect(period.price_in_cents_wo_vat).to eq 20050
      end
    end
  end

  context 'as organization' do
    it 'set values' do
      organization = FactoryBot.create(:organization)
      period = Period.create(start_date: Date.today.beginning_of_month, organization_id: organization.id)
      period.subscription = Subscription.create(organization_id: organization.id)
      option1 = ProductOptionOrder.new(name: 'Recurrent option', price_in_cents_wo_vat: 1000, duration: 0, group_position: 1)
      option2 = ProductOptionOrder.new(name: 'Ponctual option',  price_in_cents_wo_vat: 2000, duration: 1, group_position: 2)
      period.product_option_orders << option1
      period.product_option_orders << option2

      Billing::UpdatePeriodPrice.new(period).execute

      expect(period.recurrent_products_price_in_cents_wo_vat).to eq 1000
      expect(period.ponctual_products_price_in_cents_wo_vat).to eq 2000
      expect(period.products_price_in_cents_wo_vat).to eq 3000
      expect(period.excesses_price_in_cents_wo_vat).to eq 0
      expect(period.price_in_cents_wo_vat).to eq 3000
    end
  end
end
