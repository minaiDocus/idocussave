# -*- encoding : UTF-8 -*-
class DataVerificator::TempDocumentDuplicated < DataVerificator::DataVerificator
  def execute
    mcn_organization = Organization.find_by_code 'MCN'
    temp_documents = TempDocument.where('updated_at >= ? AND updated_at <= ? AND organization_id != ?', 1.days.ago, Time.now, mcn_organization.id).distinct.select(:original_file_name, :pages_number, :user_id)

    messages = []

    count = 0

    temp_documents.each do |temp_document_info|
      raw_temp_documents = TempDocument.where('updated_at >= ? AND updated_at <= ? AND original_file_name = ? AND pages_number = ? AND user_id = ?', 2.months.ago, Time.now, temp_document_info.original_file_name, temp_document_info.pages_number, temp_document_info.user_id)
      if raw_temp_documents.size > 1
        temp_document = raw_temp_documents.group_by{|element| [element[:original_file_name], element[:pages_number]]}.map{|key, value| key + [value.map{|p| [p.id, p.state, p.created_at.strftime('%d-%m-%Y %H:%M:%S'), p.api_name, p.content_file_name, p.original_fingerprint]}]}.first
        tmp_doc_elements = []
        if temp_document[0].present? && temp_document[2].size > 1
          temp_document[2].each{|tmp_doc_el| tmp_doc_elements << tmp_doc_el.join(' => ')}
          count += 1
          messages << "user_code: #{raw_temp_documents.first.user.code}, original_file_name: #{temp_document[0].gsub(/,/,' - ')}, count: #{temp_document[2].size}, pages_number: #{temp_document[1]}, details: #{tmp_doc_elements.join('<br/>')}"
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