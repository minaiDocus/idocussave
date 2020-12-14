# -*- encoding : UTF-8 -*-
class Archive::WebhookContent < ApplicationRecord
  self.table_name = 'archive_webhook_contents'

  belongs_to :retriever, optional: true
end