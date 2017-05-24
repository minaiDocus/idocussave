class FileDeliveryWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: :false

  def perform
    %w(dbx dbb box kwg ftp gdr).each do |service_prefix|
      DeliverFileWorker.perform_async(service_prefix)
    end
  end
end
