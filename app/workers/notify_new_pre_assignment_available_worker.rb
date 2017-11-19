class NotifyNewPreAssignmentAvailableWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(user_id)
    UniqueJobs.for "NotifyNewPreAssignmentAvailable-#{user_id}" do
      NotifyNewPreAssignmentAvailable.execute(user_id)
    end
  end
end
