# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Scan::Delivery do
  before(:each) do
    @period = Scan::Period.create!(start_at: Time.now, end_in: 1)
  end
  
  it "should pass from wait to received" do
    @period.delivery.received!
    @period.delivery.state.should eq('received')
  end
  
  it "should pass from received to delivered" do
    @period.delivery.update_attributes(state: 'received')
    @period.delivery.delivered!
    @period.delivery.state.should eq('delivered')
  end
  
end
