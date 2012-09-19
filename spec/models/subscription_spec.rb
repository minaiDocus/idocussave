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
    subscription = Subscription.new
    subscription.start_at = Time.now
    subscription.save
    subscription.start_at.should eq(Time.local(Time.now.year,Time.now.month,1,0,0,0))
  end

  describe 'quarterly' do
    before(:each) do
      @year = Time.now.year
      @subscription = Subscription.new(period_duration: 3)
    end

    it 'created on january should start at 1st january' do
      @subscription.start_at = Time.local(@year,1,rand(31)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,1,1,0,0,0))
    end

    it 'created on february should start at 1st january' do
      day_number = Time.local(@year,2,1,0,0,0).end_of_month.day
      @subscription.start_at = Time.local(@year,2,rand(day_number)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,1,1,0,0,0))
    end

    it 'created on mars should start at 1st january' do
      @subscription.start_at = Time.local(@year,3,rand(31)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,1,1,0,0,0))
    end

    it 'created on april should start at 1st april' do
      @subscription.start_at = Time.local(@year,4,rand(30)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,4,1,0,0,0))
    end

    it 'created on may should start at 1st april' do
      @subscription.start_at = Time.local(@year,5,rand(31)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,4,1,0,0,0))
    end

    it 'created on june should start at 1st april' do
      @subscription.start_at = Time.local(@year,6,rand(30)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,4,1,0,0,0))
    end

    it 'created on july should start at 1st july' do
      @subscription.start_at = Time.local(@year,7,rand(31)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,7,1,0,0,0))
    end

    it 'created on august should start at 1st july' do
      @subscription.start_at = Time.local(@year,8,rand(31)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,7,1,0,0,0))
    end

    it 'created on september should start at 1st july' do
      @subscription.start_at = Time.local(@year,9,rand(30)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,7,1,0,0,0))
    end

    it 'created on october should start at 1st october' do
      @subscription.start_at = Time.local(@year,10,rand(31)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,10,1,0,0,0))
    end

    it 'created on november should start at 1st october' do
      @subscription.start_at = Time.local(@year,11,rand(30)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,10,1,0,0,0))
    end

    it 'created on december should start at 1st october' do
      @subscription.start_at = Time.local(@year,12,rand(31)+1,rand(24),rand(60),rand(60))
      @subscription.save
      @subscription.start_at.should eq(Time.local(@year,10,1,0,0,0))
    end
  end
end
