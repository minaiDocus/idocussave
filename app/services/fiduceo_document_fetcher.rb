class FiduceoDocumentFetcher
  class << self
    def initiate_transactions(retrievers)
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

        if transaction.success? && transaction.retrieved_document_ids.count > 0
          fetch_documents transaction
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

    def fetch_documents(transaction)
      client = Fiduceo::Client.new transaction.user.fiduceo_id
      fetched_document_ids = transaction.temp_documents.distinct(:fiduceo_id)
      transaction.retrieved_document_ids.each do |id|
        unless id.in? fetched_document_ids
          document = client.document id
          if client.response.code == 200
            FiduceoDocument.new transaction, document
          end
        end
      end
      transaction.is_processed = true
      transaction.save
    end
  end
end
