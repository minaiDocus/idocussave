class RetrieveEmailedDocumentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :retrieve_emailed_document, retry: :false, unique: :until_and_while_executing

  def perform
    EmailedDocument.fetch_all
  end
end
