# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PeriodDelivery do
  before(:each) do
    @period = Period.create!(start_date: Date.today)
  end

  it "should pass from wait to received" do
    @period.delivery.received!
    expect(@period.delivery.state).to eq('received')
  end

  it "should pass from received to delivered" do
    @period.delivery.update(state: 'received')
    @period.delivery.delivered!
    expect(@period.delivery.state).to eq('delivered')
  end
end
