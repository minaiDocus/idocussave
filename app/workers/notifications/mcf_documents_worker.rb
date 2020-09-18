class Notifications::McfDocumentsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform()
    UniqueJobs.for "NotificationsMcfDocumentErrors" do
      Notifications::McfDocuments.new.notify_mcf_document_with_process_error
    end
  end
end