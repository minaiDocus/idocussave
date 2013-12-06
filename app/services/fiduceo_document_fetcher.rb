class FiduceoDocumentFetcher
  class << self
    def initiate_transactions(retrievers=nil)
      _retrievers = Array(retrievers).presence || FiduceoRetriever.active.providers.scheduled
      _retrievers.each do |retriever|
        if retriever.scheduled? && retriever.is_active && FiduceoTransaction.where(retriever_id: retriever.id).not_processed.count == 0
          create_transaction(retriever)
        end
      end
    end

    def create_transaction(retriever)
      client = Fiduceo::Client.new retriever.user.fiduceo_id
      result = client.retriever(retriever.fiduceo_id, :post)
      if client.response.code == 200
        transaction = FiduceoTransaction.new
        transaction.user = retriever.user
        transaction.retriever = retriever
        transaction.fiduceo_id = result['id']
        transaction.save
        retriever.fetch
        transaction
      else
        nil
      end
    end

    def fetch
      FiduceoTransaction.not_processed.each do |transaction|
        update_transaction transaction

        if transaction.success? && transaction.retriever.pending_document_ids.size > 0
          fetch_documents transaction.retriever
        end
      end
    end

    def update_transaction(transaction)
      client = Fiduceo::Client.new transaction.user.fiduceo_id
      result = client.transaction transaction.fiduceo_id
      if client.response.code == 200
        transaction.status = result['transactionStatus']
        transaction.events = result['transactionEvents']
        if result['retrievedDocuments']
          transaction.retrieved_document_ids = result['retrievedDocuments']['documentId'] || []
        end
        FiduceoTransactionTracker.track(transaction)
        transaction.save
      else
        nil
      end
    end

    def fetch_documents(retriever)
      client = Fiduceo::Client.new retriever.user.fiduceo_id
      fetched_document_ids = retriever.temp_documents.distinct(:fiduceo_id)
      retriever.pending_document_ids.each do |id|
        unless id.in? fetched_document_ids
          document = client.document id
          if client.response.code == 200
            FiduceoDocument.new retriever, document
          end
        end
        retriever.safely.update_attribute(:pending_document_ids, retriever.pending_document_ids - [id])
      end
    end
  end
end
