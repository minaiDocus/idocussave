class RetrieveFromGroupingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :retrieve_from_grouping, retry: :false, unique: :until_and_while_executing

  def perform(file_path)
    AccountingWorkflow::GroupDocument.new(file_path).execute
  end
end
