class Notifications::DematboxUploaded < Notifications::Notifier
  def self.notify_dematbox_document_uploaded(temp_doc_id, remaining_tries=0)
    new({ temp_document_id: temp_doc_id, remaining_tries: remaining_tries }).notify_dematbox_document_uploaded
  end

  def initialize(arguments={})
    super
  end

  def notify_dematbox_document_uploaded
    temp_document = TempDocument.find(@arguments[:temp_document_id])

    if temp_document.dematbox_box_id && temp_document.dematbox_doc_id
      pages_number = DocumentTools.pages_number(temp_document.cloud_content_object.path)
      message = 'Envoi OK : %02d p.' % pages_number

      begin
        result = DematboxApi.notify_uploaded temp_document.dematbox_doc_id, temp_document.dematbox_box_id, message
      rescue Savon::SOAPFault => e
        if e.message.match(/702:DocId already notified/)
          result = true
        elsif e.message.match(/703:DocId not sent/) && @arguments[:remaining_tries] > 0 && (not Rails.env.test?)
          Notifications::DematboxUploaded.delay_for(5.seconds).notify_dematbox_document_uploaded(temp_document.id, (@arguments[:remaining_tries] - 1))
        else
          raise
        end
      end

      if result == '200:OK' || result == true
        temp_document.update(dematbox_is_notified: true, dematbox_notified_at: Time.now)

        # Note : not used, since we do not process OCR through Sagemcom anymore
        # if temp_document.uploaded?
        #   DematboxServiceApi.upload_notification temp_document.dematbox_doc_id, temp_document.dematbox_box_id
        # end
      end
    end
  end
end