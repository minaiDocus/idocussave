module SendTempDocumentToOcrProcessor
  def execute(temp_document_id)
    temp_document = TempDocument.find(temp_document_id)

    doc_id        = DematboxServiceApi.send_file(temp_document.content.path)

    temp_document.update_attribute(:dematbox_doc_id, doc_id)
  end
end
