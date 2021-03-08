class PonctualScripts::MigratePreviousPeriodBillingHistory < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end


  def self.rollback
    new().rollback
  end


  private


  def periods
    Period.where('created_at BETWEEN ? AND ? AND user_id > 0', Date.new(2020, 1).beginning_of_month, Date.new(2021, 2).end_of_month)
  end


  def execute
    logger_infos "#{periods.size} periods found for billing history"
    counter = 0

    periods.each do |period|
      next if period.user.nil?
      counter += 1
      BillingHistory.create(value_period: period.start_date.strftime('%Y%m').to_i, user: period.user, period: period, state: 'processed', amount: period.price_in_cents_w_vat)
    end

    logger_infos "#{counter} periods billing_histories created"
  end


  def backup
    logger_infos "#{periods.size} periods found to be backing up"
    counter = 0

    periods.each do |period|
      next if period.user.nil?
      counter += 1
      period.billing_histories.destroy_all
    end

    logger_infos "#{counter} periods billing_histories backed up"
  end
end