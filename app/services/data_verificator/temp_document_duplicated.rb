# -*- encoding : UTF-8 -*-
class DataVerificator::TempDocumentDuplicated < DataVerificator::DataVerificator
  def execute
    temp_documents = TempDocument.where(updated_at: [2.days.ago..Time.now])

    messages = []

    _temp_documents = temp_documents.group_by{|element| [element[:original_file_name], element[:pages_number]]}.map{|key, value| key + [value.map(&:original_fingerprint)]}

    _temp_documents.each do |temp_document|
      messages << "original_fine_name: #{temp_document[0]}, pages_number: #{temp_document[1]}, original_fingerprint: #{temp_document[2]}" if temp_document[2].size > 1
    end

    {
      title: "TempDocumentDuplicated - #{_temp_documents.size} TempDocument(s) duplicated original_file_name and pages_number found",
      type: "table",
      message: messages.join('; ')
    }
  end
end