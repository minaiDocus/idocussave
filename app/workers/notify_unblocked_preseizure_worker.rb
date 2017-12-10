class NotifyUnblockedPreseizureWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(user_id)
    UniqueJobs.for "NotifyUnblockedPreseizure-#{user_id}" do
      NotifyUnblockedPreseizure.execute(user_id)
    end
  end
end
