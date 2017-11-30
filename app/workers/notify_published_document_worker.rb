class NotifyPublishedDocumentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(user_id)
    UniqueJobs.for "NotifyPublishedDocument-#{user_id}" do
      NotifyPublishedDocument.execute(user_id)
    end
  end
end
