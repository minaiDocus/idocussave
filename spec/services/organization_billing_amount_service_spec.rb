# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe OrganizationBillingAmountService do
  it 'returns 5000' do
    Timecop.freeze Time.local(2015)
    # First customer, monthly
    customer1 = FactoryGirl.create(:user, code: 'TS%0001')
    subscription = customer1.find_or_create_subscription
    option = SubscriptionOption.create(name: 'Option', price_in_cents_wo_vat: 2500, period_duration: 0)
    subscription.options << option
    UpdatePeriodPriceService.new(subscription.current_period).execute
    # Second customer, quarterly
    customer2 = FactoryGirl.create(:user, code: 'TS%0002')
    subscription2 = customer2.find_or_create_subscription
    subscription2.update_attribute(:period_duration, 3)
    option2 = SubscriptionOption.create(name: 'Option 2', price_in_cents_wo_vat: 3000, period_duration: 0)
    subscription2.options << option2
    UpdatePeriodPriceService.new(subscription2.current_period).execute
    # Organization
    organization = Organization.create(name: 'TEST', code: 'TS')
    organization.customers << customer1
    organization.customers << customer2
    organization_subscription = organization.find_or_create_subscription
    option3 = SubscriptionOption.create(name: 'Option 3', price_in_cents_wo_vat: 1500, position: 3, period_duration: 0)
    organization_subscription.options << option3
    UpdatePeriodPriceService.new(organization_subscription.current_period).execute

    result = OrganizationBillingAmountService.new(organization).execute

    expect(result).to eq 5000

    Timecop.return
  end
end
