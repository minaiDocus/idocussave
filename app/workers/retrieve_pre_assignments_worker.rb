class RetrievePreAssignmentsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(*args)
    UniqueJobs.for 'RetrievePreAssignments' do
      AccountingWorkflow::RetrievePreAssignments.fetch_all
    end
  end
end
