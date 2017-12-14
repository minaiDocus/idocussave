class NotifyDetectedPreseizureDuplicateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(user_id)
    UniqueJobs.for "NotifyDetectedPreseizureDuplicate-#{user_id}" do
      NotifyDetectedPreseizureDuplicate.execute(user_id)
    end
  end
end
