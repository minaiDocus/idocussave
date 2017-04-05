class DocumentNotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: :false, unique: :until_and_while_executing

  def perform
    start_at = 1.day.ago.localtime.beginning_of_day
    end_at   = start_at.end_of_day
    DocumentNotifier.notify_updated(start_at, end_at)

    DocumentNotifier.notify_pending
  end
end
