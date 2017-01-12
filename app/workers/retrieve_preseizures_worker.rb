class RetrievePreseizuresWorker
  include Sidekiq::Worker
  sidekiq_options queue: :retrieve_preseizures, retry: :false, unique: :until_and_while_executing

  def perform(*args)
    AccountingWorkflow::RetrievePreAssignments.fetch_all
  end
end
