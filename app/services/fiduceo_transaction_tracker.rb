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
        if transaction.not_retryable?
          content = ""
          content << "Utilisateur : #{transaction.user.code}<br>"
          content << "Récupérateur : #{transaction.retriever.name} - (#{transaction.retriever.service_name})<br>"
          content << "Transaction : #{transaction.status} - #{transaction.id}<br>"
          content << "<br><br>#{transaction.events.inspect}"
          ErrorNotification::EMAILS.each do |email|
            NotificationMailer.notify(email, "[iDocus] Erreur transaction fiduceo - #{transaction.status}", content).deliver
          end
        end
      end
      if transaction.retrieved_document_ids.any?
        retriever.safely.update_attribute(:pending_document_ids, retriever.pending_document_ids + transaction.retrieved_document_ids)
      end
    end
  end
end
