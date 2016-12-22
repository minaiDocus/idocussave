class DeliverPreAssignmentsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :pre_assignments_delivery, retry: :false, unique: :until_and_while_executing


  def perform(*args)
    PreAssignmentDeliveryService.execute
  end
end
