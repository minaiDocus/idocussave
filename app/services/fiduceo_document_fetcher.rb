# -*- encoding : UTF-8 -*-
class FiduceoDocumentFetcher
  class << self
    def initiate_transactions(retrievers=nil)
      _retrievers = Array(retrievers).presence || FiduceoRetriever.active.auto.every_day.where(:state.in => %w(scheduled error))
      _retrievers.each do |retriever|
        if (retriever.ready? || retriever.scheduled? || retriever.error?) && retriever.is_active && retriever.transactions.not_processed.count == 0
          retriever.schedule if retriever.error?
          create_transaction(retriever)
        end
      end
    end

    def create_transaction(retriever)
      client = Fiduceo::Client.new retriever.user.fiduceo_id
      result = client.retriever(retriever.fiduceo_id, :post)
      if client.response.code == 200
        transaction                     = FiduceoTransaction.new
        transaction.user                = retriever.user
        transaction.retriever           = retriever
        transaction.fiduceo_id          = result['id']
        transaction.type                = retriever.type
        transaction.service_name        = retriever.service_name
        transaction.custom_service_name = retriever.name
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
        if previous_transaction.blank?
          retriever.schedule
          initiate_transactions retriever
        end
      end
    end

    def fetch
      # prepare_retryable_retrievers
      transactions = FiduceoTransaction.not_processed.entries
      transactions += FiduceoRetriever.not_processed.map do |retriever|
        retriever.transactions.desc(:created_at).first
      end.compact
      transactions.uniq.each do |transaction|
        update_transaction transaction

        if (transaction.success? || transaction.acceptable?) && transaction.retriever && transaction.retriever.pending_document_ids.size > 0
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
        transaction.save
        update_retriever_by_transaction(transaction)
      else
        nil
      end
    end

    def update_retriever_by_transaction(transaction)
      retriever = transaction.retriever.try(:reload)
      if retriever
        retriever.timeless.update_attribute(:transaction_status, transaction.status)
        if transaction.wait_for_user_action? && retriever.processing?
          retriever.wait_for_user_action
        elsif (transaction.success? || transaction.acceptable?) && (retriever.processing? || retriever.wait_for_user_action?)
          if retriever.is_selection_needed
            if retriever.provider?
              if transaction.retrieved_document_ids.count > 0
                retriever.wait_selection
                retriever.update_attribute(:is_selection_needed, false)
              else
                transaction.acceptable? ? retriever.error : retriever.schedule
              end
            else
              retriever.wait_selection
              retriever.update_attribute(:is_selection_needed, false)
            end
          else
            if transaction.acceptable?
              retriever.error
            else
              retriever.schedule
              retriever.bank_accounts.update_all(is_operations_up_to_date: false) if retriever.bank?
            end
          end
          if transaction.retrieved_document_ids.any?
            retriever.with(safe: true).update_attribute(:pending_document_ids, retriever.pending_document_ids + transaction.retrieved_document_ids)
          end
        elsif transaction.error? && (retriever.processing? || retriever.wait_for_user_action?)
          retriever.error
          if transaction.critical_error?
            addresses = Array(Settings.notify_errors_to)
            FiduceoRetrieverMailer.notify_transaction_error(addresses, transaction).deliver if addresses.size > 0
          end
        end
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
      documents = []
      retriever.pending_document_ids.each do |id|
        if id.in? fetched_document_ids
          retriever.with(safe: true).update_attribute(:pending_document_ids, retriever.pending_document_ids - [id])
        else
          document = client.document id
          if client.response.code == 200
            documents << document
            retriever.with(safe: true).update_attribute(:pending_document_ids, retriever.pending_document_ids - [id])
          end
        end
      end
      documents.sort_by do |document|
        date = document['metadatas']['metadata'].select { |e| e['name'] == 'DATE' }.first['value']
        if date.present?
          Time.zone.parse(date).to_time
        else
          Time.now
        end
      end.each do |document|
        FiduceoDocument.new retriever, document
      end
      if retriever.wait_selection? && retriever.temp_documents.count == 0
        retriever.schedule
      end
    end
  end
end
