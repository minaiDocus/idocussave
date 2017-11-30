class RetrieverNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    RetrieverNotification.notify_summary_updates
    RetrieverNotification.notify_no_bank_account_configured
  end
end
