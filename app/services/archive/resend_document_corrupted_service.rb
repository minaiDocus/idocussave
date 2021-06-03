class Archive::ResendDocumentCorruptedService
  def self.execute
    new().execute
  end

  def execute
    Archive::DocumentCorrupted.resend.each do |document|
      params = document.params

      uploaded_document = UploadedDocument.new(File.open(document.cloud_content_object.path), params[:original_file_name], params[:user], params[:journal], params[:prev_period_offset], document.user, params[:api_name], params[:analytic], params[:api_id], false, 'worker')
    end

    Archive::DocumentCorrupted.to_notify.group_by{|u| u.user }.each do |user, documents|
      mail = []
      mail << { uploader: user, collaborator: user.prescribers, documents: documents }

      DocumentCorruptedAlertMailer.notify(mail.first).deliver
    end

    Archive::DocumentCorrupted.old_documents.each do |document|
      document.destroy
    end
  end  
end