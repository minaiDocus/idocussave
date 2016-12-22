# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class FiduceoBalance
  def initialize(user_id, bank_account_id, options = {})
    @user_id = user_id
    @bank_account_id = bank_account_id
    @type = options[:type] || 'monthly'
    @start_date = options[:start_date].try(:to_time) || Time.now.beginning_of_year
    if @type == 'monthly'
      count = (Time.now - @start_date).abs.round / 1.month.to_i
    elsif @type == 'daily'
      count = (Time.now - @start_date).abs.round / 1.day.to_i
    end
    @history_count = options[:history_count] || count
    @previ_count = options[:previ_count] || count
  end


  def balances
    results = client.bank_account_balances(@bank_account_id, @type, @history_count, @previ_count)
    if client.response.code == 200
      results[1].each do |balance|
        balance.date = balance.date.to_date
        balance.amount = balance.amount.to_f
      end
    else
      false
    end
  end

  private


  def client
    @client ||= Fiduceo::Client.new @user_id
  end
end
