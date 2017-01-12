class DematboxNotifyUploadedWorker
  include Sidekiq::Worker
  sidekiq_options retry: :false, queue: :dematbox


  def perform(temp_document_id)
    DematboxNotifyUploaded.execute(temp_document_id)
  end
end
