class UploadedDocumentPresenter
  def initialize(uploaded_document)
    @uploaded_document = uploaded_document
  end

  def to_json
    file = {}
    data = []
    temp_document = @uploaded_document.temp_document

    if @uploaded_document.valid? && temp_document
      file[:created_at] = I18n.l(temp_document.created_at)
      file[:name]       = temp_document.original_file_name
      file[:new_name]   = temp_document.cloud_content_object.filename

      if temp_document.state == 'bundle_needed'
        file[:message] = 'Vos documents sont en-cours de traitement, ils seront visibles dans quelques heures dans votre espace'
      end
    else
      file[:name]  = @uploaded_document.original_file_name
      file[:error] = @uploaded_document.full_error_messages.presence || 'Internal error (507 - Try again later)'
      if @uploaded_document.link.present?
        file[:link] = @uploaded_document.link
        file[:original_file_name] = @uploaded_document.original_file_name
        file[:user_code] = @uploaded_document.code
        file[:journal] = @uploaded_document.journal
        file[:prev_period_offset] = @uploaded_document.prev_period_offset
        file[:api_name] = @uploaded_document.api_name
        file[:analytic] = @uploaded_document.analytic
      end

      file[:file_corrupted] = file[:error].match /Votre document est en-cours/
    end

    data << file
    { files: data }.to_json
  end
end
