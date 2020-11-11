class AccountingPlan::IbizaUpdateWorker
  include Sidekiq::Worker

  def perform(user_id=nil)
    if user_id.present?
      customer = User.find user_id
      AccountingPlan::IbizaUpdateWorker::Launcher.delay.update_ibiza_for(customer.id)
    else
      UniqueJobs.for "AccountingPlanIbizaUpdateOrganization", 1.day do
        Organization.all.each do |organization|
          organization.customers.active.order(code: :asc).each do |customer|
            AccountingPlan::IbizaUpdateWorker::Launcher.delay.update_ibiza_for(customer.id)
            sleep(5)
          end
        end
      end
    end
  end

  class Launcher
   def self.update_ibiza_for(customer_id)
      UniqueJobs.for "AccountingPlanIbizaUpdate-#{customer_id}", 1.day do
        customer = User.find(customer_id)

        AccountingPlan::IbizaUpdate.new(customer).run if customer.organization.ibiza.try(:configured?)
        AccountingWorkflow::MappingGenerator.new([customer]).execute
      end
    end
  end
end