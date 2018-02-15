class DematboxNotifyUploadedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high

  def perform(temp_document_id, remaining_tries=0)
    DematboxNotifyUploaded.execute(temp_document_id, remaining_tries)
  end
end
