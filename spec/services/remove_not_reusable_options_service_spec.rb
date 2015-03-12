# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe RemoveNotReusableOptionsService do
  it 'remove options unless duration is 0' do
    subscription = Subscription.create
    option  = ProductOption.create(name: 'ponctual',  title: 'Option 1', price_in_cents_wo_vat: 1000, duration: 1)
    option2 = ProductOption.create(name: 'recurrent', title: 'Option 2', price_in_cents_wo_vat: 2500, duration: 0)
    subscription.options << option
    subscription.options << option2

    RemoveNotReusableOptionsService.new(subscription).execute

    expect(subscription.options).to eq([option2])
  end
end
