class DeliverRemoteFilesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :remote_file_delivery, retry: :false, unique: :until_and_while_executing


  def perform(category)
    Delivery.process(category)
  end
end
