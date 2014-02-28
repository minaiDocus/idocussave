class FiduceoDocumentFetcher
  class << self
    def initiate_transactions(retrievers=nil)
      _retrievers = Array(retrievers).presence || FiduceoRetriever.active.providers.scheduled
      _retrievers.each do |retriever|
        if (retriever.scheduled? || (retriever.error? && retriever.transactions.last.try(:retryable?))) && retriever.is_active && FiduceoTransaction.where(retriever_id: retriever.id).not_processed.count == 0
          retriever.schedule if retriever.error?
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

    def prepare_retryable_retrievers
      FiduceoRetriever.error.where(:updated_at.gte => 6.minutes.ago, :updated_at.lte => 5.minutes.ago).each do |retriever|
        last_transaction = retriever.transactions.desc(:created_at).first
        previous_transaction = retriever.transactions.where(:updated_at.lt => last_transaction.created_at,
                                                            :updated_at.gte => (last_transaction.created_at - 6.minutes)).first
        if previous_transaction.blank? && last_transaction.retryable?
          retriever.schedule
          initiate_transactions retriever
        end
      end
    end

    def fetch
      prepare_retryable_retrievers
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
        if result['waitForUserLabel']
          transaction.wait_for_user_labels = result['waitForUserLabel'].split('||')
        end
        if result['retrievedDocuments']
          transaction.retrieved_document_ids = Array(result['retrievedDocuments']['documentId'])
        end
        FiduceoTransactionTracker.track(transaction)
        transaction.save
      else
        nil
      end
    end

    def send_additionnal_information(transaction, answers)
      client = Fiduceo::Client.new transaction.user.fiduceo_id
      client.put_transaction transaction.fiduceo_id, answers.join('||')
      client.response.code == 200
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
      if retriever.wait_selection? && retriever.temp_documents.count == 0
        retriever.schedule
      end
    end
  end
end
