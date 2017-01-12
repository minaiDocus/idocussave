class UpdateAccountingPlanWorker
  include Sidekiq::Worker


  def perform(*args)
    UpdateAccountingPlan.execute
    AccountingWorkflow::MappingGenerator.execute
  end
end
