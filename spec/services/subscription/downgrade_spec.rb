# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Subscription::Downgrade do
  it "removes options who's period_duration are not 0" do
    subscription = Subscription.create
    option  = SubscriptionOption.create(name: 'Option 1', price_in_cents_wo_vat: 1000, position: 1, period_duration: 1)
    option2 = SubscriptionOption.create(name: 'Option 2', price_in_cents_wo_vat: 2500, position: 2, period_duration: 0)
    subscription.options << option
    subscription.options << option2

    Subscription::Downgrade.new(subscription, false).execute

    expect(subscription.options).to eq([option2])
  end

  it 'disables unneeded packages' do
    subscription = Subscription.new
    subscription.is_scan_box_package_active     = true
    subscription.is_mail_package_active         = true
    subscription.is_mail_package_to_be_disabled = true
    subscription.is_pre_assignment_active        = false
    subscription.save

    Subscription::Downgrade.new(subscription, false).execute

    expect(subscription.is_scan_box_package_active).to     eq(true)
    expect(subscription.is_mail_package_active).to         eq(false)
    expect(subscription.is_mail_package_to_be_disabled).to eq(false)
  end
end
