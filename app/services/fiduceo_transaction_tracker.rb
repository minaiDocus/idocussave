# -*- encoding : UTF-8 -*-
class FiduceoTransactionTracker
  def self.track(transaction)
    retriever = transaction.retriever
    if transaction.status_changed?
      if transaction.success?
        if retriever.is_documents_locked
          if transaction.retrieved_document_ids.count > 0
            retriever.wait_user_action
          else
            retriever.schedule
          end
          retriever.update_attribute(:is_documents_locked, false)
        else
          retriever.schedule
        end
      elsif transaction.error?
        retriever.error
      end
    end
  end
end
