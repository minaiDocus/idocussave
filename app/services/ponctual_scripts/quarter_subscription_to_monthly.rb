class PonctualScripts::QuarterSubscriptionToMonthly < PonctualScripts::PonctualScript
  def self.execute
    new({run_once: true}).run
  end

  private

  def execute
    subscriptions = Subscription.where(period_duration: 3).where('user_id > 0')

    logger_infos "#{subscriptions.size} subscriptions found"
    counter = 0

    subscriptions.each do |subs|
      user = subs.user
      subs.period_duration = 1

      if user && subs.save
        logger_infos "[Sub] - ( user_code: #{user.try(:my_code) || 'no_user'} - user_active: #{(user.still_active?).to_s} ) | id: #{subs.id} - duration: #{subs.period_duration} - start_date: #{subs.start_date} - end_date: #{subs.end_date}"
        subs.reload.set_start_date_and_end_date

        if user.still_active?
          period = subs.current_period
          period.send(:set_start_date_and_end_date)

          Billing::UpdatePeriod.new(period).execute
          UpdatePeriodDataService.new(period).execute
          UpdatePeriodPriceService.new(period).execute
          counter += 1
        end
      end
    end

    logger_infos "#{counter} subscriptions updated"
  end
end