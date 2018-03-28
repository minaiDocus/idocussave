class NotifyPreAssignmentDeliveryFailureDailyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'NotifyPreAssignmentDeliveryFailureDaily' do
      NotifyPreAssignmentDeliveryFailure.daily
    end
  end
end
