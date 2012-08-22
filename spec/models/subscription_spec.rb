# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Subscription do
  before(:each) do
    User.destroy_all
    Subscription.destroy_all
    
    @user = User.new(first_name: 'Alice', last_name: 'Bob', email: 'client@example.com', password: 'secret', password_confirmation: 'secret', code: 'PRE0001')  
    @user.save
    
    @subscription1 = Subscription.new
    @subscription2 = Subscription.new(start_at: Time.now - 4.month)
    
    @option1 = ProductOptionOrder.new(price_in_cents_wo_vat: 500)
    @option2 = ProductOptionOrder.new(price_in_cents_wo_vat: 1000)
  
    @subscription1.product_option_orders << @option1
    @subscription1.product_option_orders << @option2
    
    @subscription1.user = @user
    @subscription1.save
    @subscription2.save  
  end
  
  describe ".by_start_date" do
    subject(:subscriptions_start_at) { Subscription.by_start_date.map { |subscription| subscription.start_at } }
    
    it { subject[0].should eq(@subscription2.start_at) }
    it { subject[1].should eq(@subscription1.start_at) }
  end
  
  it "#price_in_cents_w_vat should equal 1794" do
    @subscription1.price_in_cents_w_vat.should eq(1794)
  end 
  
  it "#total_vat should equal 294" do
    @subscription1.total_vat.should eq(294)
  end
  
  it "#update_price should equal 1500" do
    @subscription1.update_price.should eq (1500)
  end
  
  it "#update_price! should be true" do
    @subscription1.update_price!.should be(true)
  end
  
  it "#products_total_price_in_cents_wo_vat should equal 1500" do
    @subscription1.products_total_price_in_cents_wo_vat.should eq(1500)
  end
  
  it "#products_total_price_in_cents_w_vat should equal 1794" do
    @subscription1.products_total_price_in_cents_w_vat.should eq(1794)
  end
  
  it ".current should equal subscription 1" do
    Subscription.current.should eq(@subscription1)
  end
  
  it "#set_start_date" do
    @subscription2.start_at = @subscription2.start_at - 3.month
    @subscription2.save
    @subscription2.start_at.month.should eq(1)
  end
end
