class Notifications::PreAssignmentDeliveryDailyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'NotificationsPreAssignmentDeliveryFailureDaily' do
      Notifications::PreAssignments.new.notify_pre_assignment_delivery_failure_daily
    end
  end
end
