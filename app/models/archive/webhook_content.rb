# -*- encoding : UTF-8 -*-
class Archive::WebhookContent < ApplicationRecord
	ATTACHMENTS_URLS={'cloud_content' => ''}

  self.table_name = 'archive_webhook_contents'

  belongs_to :retriever, optional: true

  has_one_attached :cloud_content

  def json_content=(data)
    self.cloud_content_object.attach(StringIO.new(SymmetricEncryption.encrypt(Oj.dump(data))), 'data.blob')
  end

  def json_content
    if File.exist?(cloud_content_object.reload.path.to_s)
      begin
        { success: true, content: Oj.load(SymmetricEncryption.decrypt(File.read(cloud_content_object.path.to_s))) }
      rescue => e
        { success: false, content: e.to_s }
      end
    else
      { success: false, content: 'File not found' }
    end
  end

	def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end
end