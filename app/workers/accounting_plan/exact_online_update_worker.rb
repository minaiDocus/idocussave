class AccountingPlan::ExactOnlineUpdateWorker
  include Sidekiq::Worker

  def perform(user_id=nil)
    if user_id.present?
      customer = User.find user_id
      AccountingPlan::ExactOnlineUpdateWorker::Launcher.delay.update_exact_online_for(customer.id)
    else
      UniqueJobs.for "AccountinpPlanExactOnlineUpdateOrganization", 1.day do
        Organization.all.each do |organization|
          organization.customers.active.order(code: :asc).each do |customer|
            AccountingPlan::ExactOnlineUpdateWorker::Launcher.delay.update_exact_online_for(customer.id)
            sleep(5)
          end
        end
      end
    end
  end

  class Launcher
    def self.update_exact_online_for(customer_id)
      UniqueJobs.for "AccountinpPlanExactOnlineUpdate-#{customer_id}", 1.day do
        customer = User.find(customer_id)

        AccountingPlan::ExactOnlineUpdate.new(customer).run if customer.organization.try(:exact_online).try(:used?)
        AccountingWorkflow::MappingGenerator.new([customer]).execute
      end
    end
  end
end