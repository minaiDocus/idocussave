class NotifyProcessedRequestsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'NotifyProcessedRequests' do
      NewProviderRequest.deliver_mails
    end
  end
end
