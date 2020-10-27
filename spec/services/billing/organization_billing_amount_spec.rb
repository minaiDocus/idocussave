# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Billing::OrganizationBillingAmount do
  it 'returns 7000' do
    Timecop.freeze Time.local(2015)
    # First customer, monthly
    customer1 = FactoryBot.create(:user, code: 'TS%0001')
    customer1.options = UserOptions.create(user_id: customer1.id, is_preassignment_authorized: true)
    subscription = customer1.find_or_create_subscription
    option = SubscriptionOption.create(name: 'Option', price_in_cents_wo_vat: 2500, period_duration: 0)
    subscription.options << option
    Billing::UpdatePeriodPrice.new(subscription.current_period).execute
    # Second customer, annual
    customer2 = FactoryBot.create(:user, code: 'TS%0002')
    customer2.options = UserOptions.create(user_id: customer2.id, is_preassignment_authorized: true)
    subscription2 = customer2.find_or_create_subscription
    subscription2.update_attribute(:period_duration, 12)
    option2 = SubscriptionOption.create(name: 'Option 2', price_in_cents_wo_vat: 3000, period_duration: 0)
    subscription2.options << option2
    Billing::UpdatePeriodPrice.new(subscription2.current_period).execute
    # Organization
    organization = Organization.create(name: 'TEST', code: 'TS')
    organization.customers << customer1
    organization.customers << customer2
    organization_subscription = organization.find_or_create_subscription
    option3 = SubscriptionOption.create(name: 'Option 3', price_in_cents_wo_vat: 1500, position: 3, period_duration: 0)
    organization_subscription.options << option3
    Billing::UpdatePeriodPrice.new(organization_subscription.current_period).execute

    result = Billing::OrganizationBillingAmount.new(organization).execute

    expect(result).to eq 7000

    Timecop.return
  end
end
