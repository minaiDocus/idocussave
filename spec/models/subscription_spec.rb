# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Subscription do
  before(:each) do
    User.destroy_all
    Subscription.destroy_all

    @user = User.new(first_name: 'Alice', last_name: 'Bob', email: 'client@example.com', password: 'secret', password_confirmation: 'secret', code: 'PRE0001')
    @user.save

    @subscription = Subscription.new

    @option1 = ProductOptionOrder.new(price_in_cents_wo_vat: 500)
    @option2 = ProductOptionOrder.new(price_in_cents_wo_vat: 1000)

    @subscription.product_option_orders << @option1
    @subscription.product_option_orders << @option2

    @subscription.user = @user
    @subscription.save
  end

  it "#price_in_cents_w_vat should equal 1800" do
    @subscription.price_in_cents_w_vat.should eq(1800)
  end

  it "#total_vat should equal 300" do
    @subscription.total_vat.should eq(300)
  end

  it "#update_price should equal 1500" do
    @subscription.update_price.should eq (1500)
  end

  it "#update_price! should be true" do
    @subscription.update_price!.should be(true)
  end

  it "#products_total_price_in_cents_wo_vat should equal 1500" do
    @subscription.products_total_price_in_cents_wo_vat.should eq(1500)
  end

  it "#products_total_price_in_cents_w_vat should equal 1800" do
    @subscription.products_total_price_in_cents_w_vat.should eq(1800)
  end
end
