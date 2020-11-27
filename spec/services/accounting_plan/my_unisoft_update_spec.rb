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

    my_unisoft    = Software::MyUnisoft.create( encrypted_api_token: "QEVuQwBAEAByOREAFhHULN2CJGaf125G4YhHmu/s35ujaoOnwQc65t/n8HeJfIfBhI2aU0wt73fJCiLh51pa9bkB79K61o7Xvru4rIX2v4q+SAkGZrwM04HpoBLNzCaYTQwOKSlkgpbltj3kwv9uJsv+Ug2jGGD5LIxCHqS9MnBILfAmW2aJyUaoJxyAG+sAspfSHkJMHO1YN6+1i9lGqXTbQNWjx8wU0YcOJiemBlx3I1L/WVrRxg==", society_id: 3, organization_id: 7, user_id: @user.id, customer_auto_deliver: 1, organization_used: true, user_used: true, auto_update_accounting_plan: true)    
  end

  after(:each) do
    DatabaseCleaner.clean
  end
 
  it "update user's accounting plan", :update do
    VCR.use_cassette('update_accounting_plan/accounting_plan_my_unisoft') do
      AccountingPlan::MyUnisoftUpdate.execute(@user)
    end

    expect(@user.accounting_plan.customers.size).to eq 4
    expect(@user.accounting_plan.providers.size).to eq 202
  end

  it "not update user's accounting plan", :non_update do
    @user.my_unisoft.update(auto_update_accounting_plan: false)

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

    expect(@user.accounting_plan.customers.size).to eq 4
    expect(@user.accounting_plan.providers.size).to eq 202
    expect(@user.accounting_plan.customers.first.updated_at).not_to eq @user.accounting_plan.customers.first.created_at
    expect(@user.accounting_plan.providers.first.updated_at).not_to eq @user.accounting_plan.providers.first.created_at
    expect(AccountingPlanItem.count).to eq 206
  end
end
