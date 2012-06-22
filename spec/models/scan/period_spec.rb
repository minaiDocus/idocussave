require 'spec_helper'

describe Scan::Period do
  it "create one period" do
    period = Scan::Period.new
    period.should be_valid
    period.save
    period.should be_persisted
  end
end
