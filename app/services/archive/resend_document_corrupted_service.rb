class Archive::ResendDocumentCorruptedService
  def self.execute
    new().execute
  end

  def execute
    Archive::DocumentCorrupted.retryable.each do |document|
      params = document.params

      uploaded_document = UploadedDocument.new(File.open(document.cloud_content_object.path), params[:original_file_name], document.user, params[:journal], params[:prev_period_offset], params[:uploader], params[:api_name], params[:analytic], params[:api_id], false, 'worker')
    end

    Archive::DocumentCorrupted.to_notify.group_by{|doc| doc.params[:uploader] }.each do |uploader, documents|
      DocumentCorruptedAlertMailer.notify({ uploader: uploader, documents: documents }).deliver
      documents.each{ |doc| doc.update(is_notify: true) }
    end

    # Archive::DocumentCorrupted.old_documents.each(&:destroy)
  end  
end