# -*- encoding : UTF-8 -*-
class System::CurrencyRate
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
    return false unless @resource
    CurrencyRate.transaction do
      table_rows = @resource.css("#historicalRateTbl tbody tr")
      table_rows.each do |row|
        data = row.css("td")
        CurrencyRate.create!(
          date: @date, 
          exchange_from: @currency,
          exchange_to: data[0].content,
          currency_name: data[1].content,
          exchange_rate: data[2].content.to_f,
          reverse_exchange_rate: data[3].content.to_f
        )
      end
    end
  end

  class << self
    def execute(currency, date)
      begin
        if date.is_a?(Range)
          (date.first.to_date..date.last.to_date).each do |day|
             new(currency, day).execute unless CurrencyRate.already_present? currency, day
          end
        else
          new(currency, date.to_date).execute unless CurrencyRate.already_present? currency, date.to_date 
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

end