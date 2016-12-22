class RetrieveFiduceoDocumentsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :retrieve_fiduceo_documents, retry: :false, unique: :until_and_while_executing

  def perform
    FiduceoRetriever.providers.where(transaction_status: 'COMPLETED').each do |retriever|
      FiduceoDocumentFetcher.fetch_documents(retriever) unless retriever.pending_document_ids.empty?
      puts '.'
    end
  end
end
