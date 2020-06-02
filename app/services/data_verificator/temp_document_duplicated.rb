# -*- encoding : UTF-8 -*-
class DataVerificator::TempDocumentDuplicated < DataVerificator::DataVerificator
  def execute
    mcn_organization = Organization.find_by_code 'MCN'
    temp_documents = TempDocument.where('updated_at >= ? AND updated_at <= ? AND organization_id != ?', 2.days.ago, Time.now, mcn_organization.id).distinct.select(:original_file_name, :pages_number, :user_id)

    messages = []

    count = 0

    temp_documents.each do |temp_document_info|
      raw_temp_documents = TempDocument.where('updated_at >= ? AND updated_at <= ? AND original_file_name = ? AND pages_number = ? AND user_id = ?', 2.months.ago, Time.now, temp_document_info.original_file_name, temp_document_info.pages_number, temp_document_info.user_id)
      if raw_temp_documents.size > 1
        _temp_document = raw_temp_documents.group_by{|element| [element[:original_file_name], element[:pages_number]]}.map{|key, value| key + [value.map{|p| [p.api_name, p.content_file_name, p.original_fingerprint]}]}.first
        tmp_doc_elements = []
        if _temp_document[0].present? && _temp_document[2].size > 1
          _temp_document[2].each{|tmp_doc_el| tmp_doc_elements << tmp_doc_el.join(' => ')}
          count += 1
          messages << "user_code: #{_temp_document.user.code}, original_file_name: #{_temp_document[0]}, count: #{_temp_document[2].size}, pages_number: #{_temp_document[1]}, details: #{tmp_doc_elements.join('<br/>')}"
        end
      end
    end

    {
      title: "TempDocumentDuplicated - #{count} TempDocument(s) duplicated original_file_name and pages_number found",
      type: "table",
      message: messages.join('; ')
    }
  end
end