# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe OrganizationBillingAmountService do
  it 'returns 6000' do
    Timecop.freeze Time.local(2015)
    # First customer, monthly
    customer1 = FactoryGirl.create(:user, code: 'TS%0001')
    subscription = customer1.find_or_create_subscription
    option = ProductOption.create(name: 'option', title: 'Option', price_in_cents_wo_vat: 2500, duration: 0)
    subscription.options << option
    subscription.current_period.update_information!
    # Second customer, quarterly
    customer2 = FactoryGirl.create(:user, code: 'TS%0002')
    subscription2 = customer2.find_or_create_subscription
    subscription2.update_attribute(:period_duration, 3)
    option2 = ProductOption.create(name: 'option_2', title: 'Option 2', price_in_cents_wo_vat: 3000, duration: 0)
    subscription2.options << option2
    subscription2.current_period.update_information!
    # Organization
    organization = Organization.create(name: 'TEST', code: 'TS')
    organization.members << customer1
    organization.members << customer2
    organization_subscription = organization.find_or_create_subscription
    group = ProductGroup.create(name: 'group', title: 'Groupe', position: 1000)
    option3 = ProductOption.create(name: 'option_3', title: 'Option 3', price_in_cents_wo_vat: 1500, position: 3, duration: 0)
    group.product_options << option3
    organization_subscription.options << option3
    organization_subscription.current_period.update_information!

    result = OrganizationBillingAmountService.new(organization).execute

    expect(result).to eq 5000

    Timecop.return
  end
end
