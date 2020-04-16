# -*- encoding : UTF-8 -*-
class DataVerificator::TempDocumentUploadedByApiName < DataVerificator::DataVerificator
  def execute
    api_names = TempDocument.all.select(:api_name).distinct.pluck(:api_name)

    messages = []
    api_names.each do |api_name|
      count = TempDocument.where(updated_at: [1.days.ago..Time.now], api_name: api_name).size
      api_name = 'Aucun' if !api_name.present?
      messages << "api_name: #{api_name}, count: #{count}"
    end

    {
      title: "TempDocumentUploadedByApiName - #{api_names.size} api name found",
      type: "table",
      message: messages.join('; ')
    }
  end
end