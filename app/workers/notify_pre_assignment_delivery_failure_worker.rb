class NotifyPreAssignmentDeliveryFailureWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(user_id)
    UniqueJobs.for "NotifyPreAssignmentDeliveryFailure-#{user_id}" do
      NotifyPreAssignmentDeliveryFailure.execute(user_id)
    end
  end
end
