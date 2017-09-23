class InitializePeriodsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'InitializePeriods' do
      Organization.all.each do |organization|
        next unless organization.is_active

        DowngradeSubscription.new(organization.subscription).execute
        organization.customers.active_at(1.month.ago).each do |customer|
          begin
            subscription = customer.subscription
            if customer.active?
              if subscription.period_duration == 1 || (subscription.period_duration == 3 && Time.now.month == Time.now.beginning_of_quarter.month) || (subscription.period_duration == 12 && Time.now.month == 1)
                DowngradeSubscription.new(subscription).execute
              end
              subscription.current_period
            end
            if subscription.period_duration != 1
              time = 1.month.ago
              period = subscription.find_period time.to_date
              PeriodBillingService.new(period).save(time.month) if period
            end
            print '.'
          rescue
            puts "Can't generate period for user #{customer.info}, probably lack of subscription entry."
          end
        end
      end
    end
  end
end
