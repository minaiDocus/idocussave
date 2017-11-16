class NotifyDocumentBeingProcessedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high

  def perform(user_id)
    UniqueJobs.for "NotifyDocumentBeingProcessedWorker-#{user_id}" do
      NotifyDocumentBeingProcessed.execute(user_id)
    end
  end
end
