# -*- encoding : UTF-8 -*-
class DataVerificator::TempDocumentUnreadable < DataVerificator::DataVerificator
  def execute
    temp_documents = TempDocument.where(state: 'unreadable', created_at: [2.days.ago..Time.now])
    bundle_needed = []
    ready         = []
    messages = []

    temp_documents.each do |temp_document|
      if temp_document.is_bundle_needed? && temp_document.parents_documents_pages.blank?
        children = temp_document.children
        next if children.present?

        # temp_document.state = 'bundle_needed'
        bundle_needed << temp_document.id
      else
        # temp_document.state = 'ready'
        ready << temp_document.id
      end

      # temp_document.save
    end

    messages << "Ready: #{ready}, Bundle_needed: #{bundle_needed}"


    {
      title: "TempDocumentUnreadable - #{temp_documents.size} unreadable temp documents found",
      message: messages.join('; ')
    }
  end
end