class UpdateAccountingPlanWorker
  include Sidekiq::Worker

  def perform(user_id=nil)
    if user_id.present?
      user = User.find user_id
      UniqueJobs.for "UpdateAccountingPlan-#{user_id}", 1.day do
        UpdateAccountingPlan.new(user).execute
        AccountingWorkflow::MappingGenerator.new([user]).execute
      end
    else
      UniqueJobs.for "UpdateAccountingPlan_all", 1.day do
        UpdateAccountingPlan.execute
        AccountingWorkflow::MappingGenerator.execute
      end
    end
  end
end
