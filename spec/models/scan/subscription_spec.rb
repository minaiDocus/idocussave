# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Scan::Subscription do
  before (:each) do
    @start_at = Time.now

    @user = User.new(:email => "client@example.com", :password => "secret", :code => "PRE0001")
    @user.skip_confirmation!
    @user.save
    
    @prescriber = User.new(:email => "prescriber@example.com", :password => "secret", :code => "PRE", :is_prescriber => true)
    @prescriber.skip_confirmation!
    @prescriber.save

    @user.prescriber = @prescriber
    @user.save
    
    @poo = ProductOptionOrder.new(:title => "reuse", :price_in_cents_wo_vat => 1000, :duration => 1)
    @poo2 = ProductOptionOrder.new(:title => "don't reuse", :price_in_cents_wo_vat => 2500, :duration => 0)
    
    @scan_subscription = Scan::Subscription.new
    @scan_subscription.code = @user.code
    @scan_subscription.start_at = @start_at
    @scan_subscription.product_option_orders = [@poo,@poo2]
    @scan_subscription.save
  end
  
  it "check default entry" do
    @scan_subscription.should be_persisted
    @scan_subscription.category.should eq(1)
    @scan_subscription.period_duration.should eq(1)
    @scan_subscription.current_progress.should eq(1)
    @scan_subscription.max_sheets_authorized.should eq(100)
    @scan_subscription.max_upload_pages_authorized.should eq(200)
    @scan_subscription.quantity_of_a_lot_of_upload.should eq(200)
    @scan_subscription.max_preseizure_pieces_authorized.should eq(100)
    @scan_subscription.max_expense_pieces_authorized.should eq(100)
    @scan_subscription.unit_price_of_excess_sheet.should eq(12)
    @scan_subscription.price_of_a_lot_of_upload.should eq(200)
    @scan_subscription.unit_price_of_excess_preseizure.should eq(0)
    @scan_subscription.unit_price_of_excess_expense.should eq(0)
    @scan_subscription.start_at.should eq(@start_at.beginning_of_month)
    @scan_subscription.end_at.should eq(@start_at.beginning_of_month + 12.month - 1.second)
    @scan_subscription.code.should eq("PRE0001")
  end
  
  it "should set category to 1" do
    scan_subscription = Scan::Subscription.new
    scan_subscription.set_category
    scan_subscription.category.should eq(1)
  end
  
  it "should verify ponctual options not reused through month" do
    period = @scan_subscription.periods.first
    period.product_option_orders.count.should eq(2)
    @scan_subscription.product_option_orders.count.should eq(1)
  end

  it "should find default period" do
    period = @scan_subscription.periods.first
    found_period = @scan_subscription.find_period(Time.now)
    found_period.should eq(period)
  end
  
  it "should find period by time" do
    time = Time.now + 2.month

    period = Scan::Period.new
    period.start_at = time
    period.duration = @scan_subscription.period_duration
    period.subscription = @scan_subscription
    period.user = @user
    period.save

    period2 = @scan_subscription.find_period(time)
    period2.should eq(period)

    period3 = @scan_subscription._find_period(time)
    period3.should eq(period)
  end
  
  it "should copy from another scan_subscription" do
    @scan_subscription.update_attributes(:period_duration => 2)
  
    scan_subscription = Scan::Subscription.new
    scan_subscription.code = @user.code
    scan_subscription.copy! @scan_subscription
    
    scan_subscription.end_in.should eq(@scan_subscription.end_in)
    scan_subscription.payment_type.should eq(@scan_subscription.payment_type)
    scan_subscription.period_duration.should eq(@scan_subscription.period_duration)
    scan_subscription.max_sheets_authorized.should eq(@scan_subscription.max_sheets_authorized)
    scan_subscription.max_upload_pages_authorized.should eq(@scan_subscription.max_upload_pages_authorized)
    scan_subscription.quantity_of_a_lot_of_upload.should eq(@scan_subscription.quantity_of_a_lot_of_upload)
    scan_subscription.max_preseizure_pieces_authorized.should eq(@scan_subscription.max_preseizure_pieces_authorized)
    scan_subscription.max_expense_pieces_authorized.should eq(@scan_subscription.max_expense_pieces_authorized)
    scan_subscription.unit_price_of_excess_sheet.should eq(@scan_subscription.unit_price_of_excess_sheet)
    scan_subscription.price_of_a_lot_of_upload.should eq(@scan_subscription.price_of_a_lot_of_upload)
    scan_subscription.unit_price_of_excess_preseizure.should eq(@scan_subscription.unit_price_of_excess_preseizure)
    scan_subscription.unit_price_of_excess_expense.should eq(@scan_subscription.unit_price_of_excess_expense)

    scan_subscription.product_option_orders.should eq(@scan_subscription.product_option_orders)
  end
  
end
