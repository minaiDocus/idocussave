class AccountingPlan::MyUnisoftUpdateWorker
  include Sidekiq::Worker

  def perform(user_id=nil)
    if user_id.present?
      customer = User.find user_id
      AccountingPlan::MyUnisoftUpdateWorker::Launcher.delay.update_my_unisoft_for(customer.id)
    else
      UniqueJobs.for "AccountingPlanMyUnisoftUpdateOrganization", 1.day do
        Organization.all.each do |organization|          
          organization.customers.order(code: :asc).active.each do |customer|
            AccountingPlan::MyUnisoftUpdateWorker::Launcher.delay.update_my_unisoft_for(customer.id)

            sleep(5)
          end
        end
      end
    end
  end

  class Launcher
   def self.update_my_unisoft_for(customer_id)
      UniqueJobs.for "AccountingPlanMyUnisoftUpdate-#{customer_id}", 1.day do
        customer = User.find(customer_id)

        AccountingPlan::MyUnisoftUpdate.new(customer).run
      end
    end
  end
end