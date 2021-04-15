# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe System::CurrencyRate do
  before(:all) do
    Timecop.freeze(Time.local(2021,02,1))

    DatabaseCleaner.start
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'injects parsed currencies' do
    System::CurrencyRate.execute 'EUR', Date.today # IMPORTANT : here Date.today  is 31/01/2021 the needed date in database

    data_currency = CurrencyRate.of(0.days.ago, 'EUR', 'USD')
    current_rate  = data_currency.try(:exchange_rate) || 1 # IMPORTANT : strangly 0.days.ago is equivalent to 1.days.ago which is 31/01/2021 in this timecop
    reverse_rate  = data_currency.try(:reverse_exchange_rate) || 1 # IMPORTANT : strangly 0.days.ago is equivalent to 1.days.ago which is 31/01/2021 in this timecop
    currency_name = data_currency.try(:currency_name) || 1 # IMPORTANT : strangly 0.days.ago is equivalent to 1.days.ago which is 31/01/2021 in this timecop

    expect(CurrencyRate.all.count).to be > 0
    expect(current_rate).to be 1.20726
    expect(currency_name).to match /US DOLLAR/i
  end
end
