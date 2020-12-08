# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AccountingPlan::IbizaUpdate do
  before(:each) do
    DatabaseCleaner.start

    organization = create(:organization)
    @user = create(:user, ibiza_id: "{IDENTIFIER}")
    @user.build_softwares
    organization.customers << @user
    ibiza = Software::Ibiza.new(access_token: "xxxtokenxxx")
    ibiza.owner = organization
    ibiza.save
    ibiza.update state: 'valid'
    accounting_plan = AccountingPlan.new
    accounting_plan.user = @user
    accounting_plan.save

    allow_any_instance_of(User).to receive(:uses?).with(:ibiza).and_return(true)
  end

  after(:each) do
    DatabaseCleaner.clean
  end
 
  it "update user's accounting plan", :update do
    VCR.use_cassette('update_accounting_plan/accounting_plan') do
      AccountingPlan::IbizaUpdate.execute(@user)
      expect(@user.accounting_plan.customers.size).to eq 3
      expect(@user.accounting_plan.providers.size).to eq 16
    end
  end

  it 'update existing items or removes old accounting plan items', :remove do
    VCR.use_cassette('update_accounting_plan/accounting_plan') do
      AccountingPlan::IbizaUpdate.execute @user.reload
    end

    sleep(5)
    @user.reload.accounting_plan.last_checked_at = nil
    @user.accounting_plan.save
    VCR.use_cassette('update_accounting_plan/accounting_plan') do
      AccountingPlan::IbizaUpdate.execute @user.reload
    end

    expect(@user.accounting_plan.customers.size).to eq 3
    expect(@user.accounting_plan.providers.size).to eq 16
    expect(@user.accounting_plan.customers.first.updated_at).not_to eq @user.accounting_plan.customers.first.created_at
    expect(@user.accounting_plan.providers.first.updated_at).not_to eq @user.accounting_plan.providers.first.created_at
    expect(AccountingPlanItem.count).to eq 19
  end

  it 'has error' do
    VCR.use_cassette('update_accounting_plan/error') do
      @user.ibiza_id = '{INVALID}'
      updater = AccountingPlan::IbizaUpdate.execute @user

      expect(updater).to be_falsy
    end
  end
end
