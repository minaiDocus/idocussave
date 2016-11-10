# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe CreateBudgeaAccount do
  before(:all) do
    @user = FactoryGirl.create :user, code: 'IDO%0001'
    @user.options = UserOptions.create(user_id: @user.id)
  end

  it "fails to create an account" do
    expect_any_instance_of(CreateBudgeaAccount).to receive(:notify_failure)

    VCR.use_cassette('budgea/failed_create_budgea_account') do
      CreateBudgeaAccount.execute(@user)
    end

    expect(@user.budgea_account).to be_nil
  end

  it "fails to get the identifier" do
    expect_any_instance_of(CreateBudgeaAccount).to receive(:notify_failure)

    VCR.use_cassette('budgea/failed_to_fetch_budgea_account_identifier') do
      CreateBudgeaAccount.execute(@user)
    end

    expect(@user.budgea_account).not_to be_persisted
  end

  it "creates an account" do
    expect_any_instance_of(CreateBudgeaAccount).not_to receive(:notify_failure)

    VCR.use_cassette('budgea/create_budgea_account') do
      CreateBudgeaAccount.execute(@user)
    end

    expect(@user.budgea_account).to be_persisted
  end

  it "does not create another account" do
    expect_any_instance_of(CreateBudgeaAccount).not_to receive(:notify_failure)
    expect_any_instance_of(CreateBudgeaAccount).not_to receive(:client)

    # NOTE using VCR just in case
    VCR.use_cassette('budgea/create_budgea_account') do
      CreateBudgeaAccount.execute(@user)
    end
  end
end
