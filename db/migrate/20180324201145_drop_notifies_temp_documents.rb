class DropNotifiesTempDocuments < ActiveRecord::Migration
  def up
    NotifiablePublishedDocument.find_each do |n|
      Notifiable.create(notify_id: n.notify_id, notifiable_id: n.temp_document_id, notifiable_type: 'TempDocument', label: 'published')
    end

    NotifiableDocumentBeingProcessed.find_each do |n|
      Notifiable.create(notify_id: n.notify_id, notifiable_id: n.temp_document_id, notifiable_type: 'TempDocument', label: 'processing')
    end

    drop_table :notifies_temp_documents
  end

  def down
    create_table :notifies_temp_documents do |t|
      t.string :label
      t.belongs_to :notify
      t.belongs_to :temp_document

      t.index [:label, :notify_id, :temp_document_id], name: 'index_label_notify_id_temp_document_id'
    end

    Notifiable.published_documents.find_each do |n|
      NotifiablePublishedDocument.create(notify_id: n.notify_id, temp_document_id: n.notifiable_id)
    end

    Notifiable.document_being_processed.find_each do |n|
      NotifiablePublishedDocument.create(notify_id: n.notify_id, temp_document_id: n.notifiable_id)
    end
  end
end
