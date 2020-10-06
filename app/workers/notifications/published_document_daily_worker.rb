class Notifications::PublishedDocumentDailyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'NotifyPublishedDocumentDaily' do
      Notifications::Documents.new.notify_published_document_daily
    end
  end
end
