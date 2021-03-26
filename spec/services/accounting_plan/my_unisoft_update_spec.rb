# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AccountingPlan::MyUnisoftUpdate do
  before(:each) do
    DatabaseCleaner.start

    organization = create(:organization)
    @user = create(:user)    
    organization.customers << @user
    accounting_plan = AccountingPlan.new
    accounting_plan.user = @user
    accounting_plan.save

    mu1 = Software::MyUnisoft.new
    mu1.is_used = true
    mu1.owner   = organization
    mu1.auto_deliver = 1
    mu1.save

    mu2 = Software::MyUnisoft.new
    mu2.is_used = true
    mu2.owner   = @user
    mu2.encrypted_api_token = "QEVuQwBAEACqDdqsXnsqW6p5pbPq5cr51FEbulJqavwCbJF2jWseBZlEiH7kzx8JxRbumy6IrwwVK+U5rOGIdHBEYoy6OHAek22k2TWaphNtxa/b7erPHNMWw86pf93ITEKevjNVwjLtR4x+Xi1u64rnXfCwi4VMo6d2b3nNWSGNfQc0XmqHvVdBNcy9SUbVoGdNKx4wRnbLjs204JeUzm3OLWputWPyYdo/GsEnyNMn73gCCPFADw=="
    mu2.society_id = 3
    mu2.auto_deliver = 1
    mu2.is_auto_updating_accounting_plan = true
    mu2.save
  end

  after(:each) do
    DatabaseCleaner.clean
  end
 
  it "update user's accounting plan", :update do
    VCR.use_cassette('update_accounting_plan/accounting_plan_my_unisoft') do
      AccountingPlan::MyUnisoftUpdate.execute(@user)
    end

    expect(@user.accounting_plan.customers.size).to eq 19
    expect(@user.accounting_plan.providers.size).to eq 9
  end

  it "not update user's accounting plan", :non_update do
    @user.my_unisoft.update(is_auto_updating_accounting_plan: false)

    VCR.use_cassette('update_accounting_plan/accounting_plan_my_unisoft') do
      AccountingPlan::MyUnisoftUpdate.execute(@user)
    end

    expect(@user.accounting_plan.customers.size).to eq 0
    expect(@user.accounting_plan.providers.size).to eq 0
  end

  it 'update existing items or removes old accounting plan items', :remove do
    VCR.use_cassette('update_accounting_plan/accounting_plan_my_unisoft') do
      AccountingPlan::MyUnisoftUpdate.execute @user.reload
    end

    sleep(10)

    @user.reload.accounting_plan.last_checked_at = nil
    @user.accounting_plan.save
    VCR.use_cassette('update_accounting_plan/accounting_plan_my_unisoft') do
      AccountingPlan::MyUnisoftUpdate.execute @user.reload
    end

    expect(@user.accounting_plan.customers.size).to eq 19
    expect(@user.accounting_plan.providers.size).to eq 9
    expect(@user.accounting_plan.customers.first.updated_at).not_to eq @user.accounting_plan.customers.first.created_at
    expect(@user.accounting_plan.providers.first.updated_at).not_to eq @user.accounting_plan.providers.first.created_at
    expect(AccountingPlanItem.count).to eq 27
  end
end
