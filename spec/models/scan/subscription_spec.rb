# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Scan::Subscription do
  before(:all) do
    @user = FactoryGirl.create(:user, code: 'TS0001')
  end

  before(:each) do
    @start_at = Time.now

    @po = ProductOption.create(name: 'reuse', title: 'Option 1', price_in_cents_wo_vat: 1000, duration: 1)
    @po2 = ProductOption.create(name: 'dont_reuse', title: 'Option 2', price_in_cents_wo_vat: 2500, duration: 0)

    @scan_subscription = Scan::Subscription.new
    @scan_subscription.user = @user
    @scan_subscription.options << @po
    @scan_subscription.options << @po2
    @scan_subscription.save
  end

  after(:each) do
    Scan::Subscription.destroy_all
    Scan::Period.destroy_all
  end

  it "check default entry" do
    @scan_subscription.should be_persisted
    @scan_subscription.period_duration.should eq(1)
    @scan_subscription.max_sheets_authorized.should eq(100)
    @scan_subscription.max_upload_pages_authorized.should eq(200)
    @scan_subscription.quantity_of_a_lot_of_upload.should eq(200)
    @scan_subscription.max_dematbox_scan_pages_authorized.should eq(200)
    @scan_subscription.quantity_of_a_lot_of_dematbox_scan.should eq(200)
    @scan_subscription.max_preseizure_pieces_authorized.should eq(100)
    @scan_subscription.max_expense_pieces_authorized.should eq(100)
    @scan_subscription.max_paperclips_authorized.should eq(0)
    @scan_subscription.max_oversized_authorized.should eq(0)
    @scan_subscription.unit_price_of_excess_sheet.should eq(12)
    @scan_subscription.price_of_a_lot_of_upload.should eq(200)
    @scan_subscription.price_of_a_lot_of_dematbox_scan.should eq(200)
    @scan_subscription.unit_price_of_excess_preseizure.should eq(12)
    @scan_subscription.unit_price_of_excess_expense.should eq(12)
    @scan_subscription.unit_price_of_excess_paperclips.should eq(20)
    @scan_subscription.unit_price_of_excess_oversized.should eq(100)
  end

  it "should verify ponctual options not reused" do
    @scan_subscription.options.count.should eq(2)
    @scan_subscription.remove_not_reusable_options
    @scan_subscription.options.count.should eq(1)
  end

  it "should find default period" do
    period = @scan_subscription.create_period(Time.now)
    expect(@scan_subscription.find_period(Time.now)).to eq(period)
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
  end
end
