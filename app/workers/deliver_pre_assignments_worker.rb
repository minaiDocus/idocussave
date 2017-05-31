class DeliverPreAssignmentsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(*args)
    UniqueJobs.for 'DeliverPreAssignments' do
      PreAssignmentDeliveryService.execute
    end
  end
end
