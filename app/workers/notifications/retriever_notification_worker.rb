class Notifications::RetrieversWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'RetrieverNotification' do
      Notifications::Retrievers.notify_summary_updates
      Notifications::Retrievers.notify_no_bank_account_configured
    end
  end
end
