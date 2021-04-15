# -*- encoding : UTF-8 -*-
class System::CurrencyRate
  class << self
    def execute(currency, date)
      begin
        if date.is_a?(Range)
          (date.first.to_date..date.last.to_date).each do |day|
             new(currency, day).execute if not CurrencyRate.already_present? currency, day
          end
        else
          new(currency, date.to_date).execute if not CurrencyRate.already_present? currency, date.to_date
        end
      rescue Exception => e
        System::Log.info('currency_rate', "#{Time.now} - #{e.to_s}")
      end
    end

    def update_all
      CurrencyRate.lists.each do |cr|
        execute(cr, Date.today)
      end
    end

    def convert_operation_amount(operation)
      bank_account   = operation.bank_account
      current_amount = operation.amount.abs
      return current_amount unless bank_account && bank_account.try(:configured?)

      return (current_amount / CurrencyRate.get_operation_exchange_rate(operation)).round(2)
    end
  end

  def initialize(currency, date)
    begin
      tries = 0
      @currency = currency
      @date = date.to_s
      @resource = Nokogiri::HTML(open("https://www.xe.com/currencytables/?from=#{@currency}&date=#{@date}", "User-Agent" => "Mozilla/5.0"))
    rescue Exception => e
      tries += 1
      sleep(1)
      retry if tries < 5
      @resource = nil
    end
  end

  def execute
    return false if not @resource

    CurrencyRate.transaction do
      table_rows.each do |row|
        CurrencyRate.create!(
            date: @date,
            exchange_from: @currency,
            exchange_to: row['currency'],
            currency_name: currency_names[row['currency']].try(:[], 'name') || row['currency'],
            exchange_rate: row['rate'],
            reverse_exchange_rate: row['inverse']
        )
      end
    end
  end

  private

  def datas
    @datas ||= JSON.parse(@resource.at_css('#__NEXT_DATA__').content)
  end

  def table_rows
    datas.try(:[], 'props').try(:[], 'pageProps').try(:[], 'historicRates') || []
  end

  def currency_names
    datas.try(:[], 'props').try(:[], 'pageProps').try(:[], 'commonI18nResources').try(:[], 'currencies').try(:[], 'en') || {}
  end
end