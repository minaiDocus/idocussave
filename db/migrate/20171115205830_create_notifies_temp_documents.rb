class CreateNotifiesTempDocuments < ActiveRecord::Migration
  def change
    create_table :notifies_temp_documents do |t|
      t.string :label
      t.belongs_to :notify
      t.belongs_to :temp_document

      t.index [:label, :notify_id, :temp_document_id], name: 'index_label_notify_id_temp_document_id'
    end
  end
end
