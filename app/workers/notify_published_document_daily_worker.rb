class NotifyPublishedDocumentDailyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'NotifyPublishedDocumentDaily' do
      NotifyPublishedDocument.daily
    end
  end
end
