require 'spec_helper'

describe User do
  it "validate new user" do
    user = User.new(:email => "test@example.com", :password => "secret")
    user.should be_valid
    user.skip_confirmation!
    user.save
    user.should be_persisted
  end
end
