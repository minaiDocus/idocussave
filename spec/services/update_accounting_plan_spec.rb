# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe UpdateAccountingPlan do
  before(:each) do
    DatabaseCleaner.start

    organization = create(:organization)
    @user = create(:user, ibiza_id: "{IDENTIFIER}")
    organization.customers << @user
    ibiza = Ibiza.new(access_token: "xxxtokenxxx")
    ibiza.organization = organization
    ibiza.save
    ibiza.update state: 'valid'
    accounting_plan = AccountingPlan.new
    accounting_plan.user = @user
    accounting_plan.save
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it "update user's accounting plan" do
    VCR.use_cassette('update_accounting_plan/accounting_plan') do
      UpdateAccountingPlan.new(@user).execute
      expect(@user.accounting_plan.customers.size).to eq 3
      expect(@user.accounting_plan.providers.size).to eq 16
    end
  end

  it 'removes old accounting plan items' do
    VCR.use_cassette('update_accounting_plan/accounting_plan') do
      UpdateAccountingPlan.new(@user).execute
    end

    VCR.use_cassette('update_accounting_plan/accounting_plan') do
      UpdateAccountingPlan.new(@user).execute
    end

    expect(@user.accounting_plan.customers.size).to eq 3
    expect(@user.accounting_plan.providers.size).to eq 16
    expect(AccountingPlanItem.count).to eq 19
  end

  it 'has error' do
    VCR.use_cassette('update_accounting_plan/error') do
      @user.ibiza_id = '{INVALID}'
      updater = UpdateAccountingPlan.new(@user)
      expect(updater.execute).to be_falsy
      expect(updater.error_message).to eq({"error" => {"details"=>"Invalid length for a Base-64 char array or string."}})
    end
  end
end
