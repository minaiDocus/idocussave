class InitializePeriodsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'InitializePeriods' do
      Organization.all.each do |organization|
        next unless organization.is_active

        Subscription::Downgrade.new(organization.subscription).execute
        organization.customers.active_at(1.month.ago).each do |customer|
          begin
            subscription = customer.subscription

            if customer.active?
              if subscription.period_duration == 1 || (subscription.period_duration == 3 && Time.now.month == Time.now.beginning_of_quarter.month) || (subscription.period_duration == 12 && Time.now.month == 1)
                Subscription::Downgrade.new(subscription).execute
              end
              subscription.current_period
            end

            if subscription.period_duration != 1
              time = 1.month.ago
              period = subscription.find_period time.to_date
              Billing::PeriodBilling.new(period).save(time.month) if period
            end
            print '.'
          rescue
            puts "Can't generate period for user #{customer.info}, probably lack of subscription entry."
          end
        end
      end

      bank_accounts = BankAccount.should_be_disabled

      Operation.where(bank_account_id: bank_accounts.map(&:id)).update_all(api_id: nil)
      Transaction::DestroyBankAccountsWorker.perform_in(1.hours, bank_accounts.map(&:id))
    end
  end
end
