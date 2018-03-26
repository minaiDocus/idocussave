# TODO : remove this after migration
class NotifiablePublishedDocument < ActiveRecord::Base
  self.table_name = 'notifies_temp_documents'

  belongs_to :notify
  belongs_to :temp_document

  default_scope -> { where("notifies_temp_documents.label = 'published'") }

  before_save do
    self.label ||= 'published'
  end
end
