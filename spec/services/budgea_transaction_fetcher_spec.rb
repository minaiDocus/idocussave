# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe BudgeaTransactionFetcher do
  before(:all) do
    @user = User.create(code: 'IDOC%001', is_prescriber: true, is_admin: true, company: 'test')

  end

  it 'pending_spec' do
  end
end