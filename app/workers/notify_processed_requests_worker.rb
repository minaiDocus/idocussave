class NotifyProcessedRequestsWorker
  include Sidekiq::Worker
  sidekiq_options retry: :false, unique: :until_and_while_executing

  def perform
    NewProviderRequest.deliver_mails
  end
end
