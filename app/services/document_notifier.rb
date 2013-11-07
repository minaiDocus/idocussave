# -*- encoding : UTF-8 -*-
class DocumentNotifier
  class << self
    def notify_updated
      Pack.observers.disable :all do
        new_documents.each do |owner, documents|
          if owner.is_document_notifier_active
            document_names = documents.map(&:name)
            PackMailer.new_document_available(owner, document_names).deliver
            documents.each do |document|
              document.timeless.update_attribute(:is_update_notified, true)
            end
          end
        end
      end
    end

    # TODO reimplement me
    def notify_pending
      ReminderEmail.deliver
    end

    def new_documents
      Pack.not_notified_update.group_by(&:owner)
    end
  end
end
