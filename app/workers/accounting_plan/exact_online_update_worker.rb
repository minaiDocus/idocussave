class AccountingPlan::ExactOnlineUpdateWorker
  include Sidekiq::Worker

  def perform(user_id=nil)
    if user_id.present?
      customer = User.find user_id
      AccountingPlan::ExactOnlineUpdateWorker::Launcher.delay.update_exact_online_for customer
    else
      UniqueJobs.for "AccountinpPlanExactOnlineUpdateOrganization", 1.day do
        Organization.all.each do |organization|
          if organization.is_exact_online_used
            organization.customers.order(code: :asc).active.each do |customer|
              AccountingPlan::ExactOnlineUpdateWorker::Launcher.delay.update_exact_online_for(customer.id)
              sleep(5)
            end
          end
        end
      end
    end
  end

  class Launcher
    def self.update_exact_online_for(customer_id)
      UniqueJobs.for "AccountinpPlanExactOnlineUpdate-#{customer_id}", 1.day do
        customer = User.find(customer_id)

        AccountingPlan::ExactOnlineUpdate.new(customer).run
        AccountingWorkflow::MappingGenerator.new([customer]).execute
      end
    end
  end
end