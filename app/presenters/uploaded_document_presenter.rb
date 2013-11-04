class UploadedDocumentPresenter
  def initialize(uploaded_document)
    @uploaded_document = uploaded_document
  end

  def to_json
    data = []
    file = {}
    if @uploaded_document.valid?
      temp_document = @uploaded_document.temp_document
      file[:created_at] = I18n.l(temp_document.created_at)
      file[:name] = temp_document.original_file_name
      file[:new_name] = temp_document.content_file_name
    else
      file[:name] = @uploaded_document.original_file_name
      file[:error] = @uploaded_document.full_error_messages
    end
    data << file
    data.to_json
  end
end
