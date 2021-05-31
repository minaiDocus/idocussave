# -*- encoding : UTF-8 -*-
class DataVerificator::TempDocumentUnreadable < DataVerificator::DataVerificator
  def execute
    temp_documents = TempDocument.where(state: 'unreadable', created_at: [2.days.ago..Time.now])
    bundle_needed_count = 0
    ready_count         = 0
    messages = []

    temp_documents.each do |temp_document|
      if temp_document.is_bundle_needed? && temp_document.parents_documents_pages.blank?
        children = temp_document.children
        next if children.present?

        temp_document.state = 'bundle_needed'
        bundle_needed_count += 1
      else
        temp_document.state = 'ready'
        ready_count         += 1
      end

      temp_document.save
    end

    messages << "Ready: #{ready_count}, Bundle_needed: #{bundle_needed_count}, Unchanged: #{temp_documents.size - bundle_needed_count - ready_count}"


    {
      title: "TempDocumentUnreadable - #{temp_documents.size} unreadable temp documents found",
      message: messages.join('; ')
    }
  end
end