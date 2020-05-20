# -*- encoding : UTF-8 -*-
class DataVerificator::TempDocumentDuplicated < DataVerificator::DataVerificator
  def execute
    mcn_organization = Organization.find_by_code 'MCN'
    temp_documents = TempDocument.where('updated_at >= ? AND updated_at <= ? AND organization_id != ?', 2.days.ago, Time.now, mcn_organization.id)

    messages = []

    count = 0

    _temp_documents = temp_documents.group_by{|element| [element[:original_file_name], element[:pages_number]]}.map{|key, value| key + [value.map(&:original_fingerprint)]}

    _temp_documents.each do |temp_document|
      if temp_document[0].present? && temp_document[2].size > 1
        count += 1
        messages << "original_file_name: #{temp_document[0]}, count: #{temp_document[2].size}, pages_number: #{temp_document[1]}, original_fingerprint: #{temp_document[2].join('|')}"
      end
    end

    {
      title: "TempDocumentDuplicated - #{count} TempDocument(s) duplicated original_file_name and pages_number found",
      type: "table",
      message: messages.join('; ')
    }
  end
end