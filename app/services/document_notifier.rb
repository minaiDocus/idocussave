# -*- encoding : UTF-8 -*-
class DocumentNotifier
  class << self
    def notify_updated
      new_documents.each do |owner, documents|
        if owner.is_document_notifier_active
          document_names = documents.map(&:name)
          PackMailer.new_document_available(owner, document_names).deliver
          documents.each do |document|
            document.update_attribute(:notified_pages_count, document.pages_count)
          end
        end
      end
    end

    # TODO reimplement me
    def notify_pending
      ReminderEmail.deliver
    end

    def new_documents
      Pack.updated.group_by(&:owner)
    end
  end
end
