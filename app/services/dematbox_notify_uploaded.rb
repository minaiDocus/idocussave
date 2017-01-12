class DematboxNotifyUploaded
  def self.execute(temp_document_id)
    temp_document = TempDocument.find(temp_document_id)

    pages_number = DocumentTools.pages_number(temp_document.content.path)

    message = 'Envoi OK : %02d p.' % pages_number

    result = DematboxApi.notify_uploaded temp_document.dematbox_doc_id, temp_document.dematbox_box_id, message if temp_document.dematbox_box_id && temp_document.dematbox_doc_id

    if result == '200:OK'
      temp_document.dematbox_is_notified = true
      temp_document.dematbox_notified_at = Time.now
      result = temp_document.save

      if temp_document.uploaded?
        DematboxServiceApi.upload_notification temp_document.dematbox_doc_id, temp_document.dematbox_box_id if temp_document.dematbox_box_id && temp_document.dematbox_doc_id
      end
    end
  end
end
