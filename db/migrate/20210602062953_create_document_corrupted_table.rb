class CreateDocumentCorruptedTable < ActiveRecord::Migration[5.2]
  def change
    create_table :archive_document_corrupted do |t|
      t.string :fingerprint
      t.boolean :is_notify, default: false
      t.integer :retry_count, default: 0
      t.integer :user_id
      t.text :params, limit: 4294967295

      t.timestamps
    end

    add_index :archive_document_corrupted, :fingerprint
    add_index :archive_document_corrupted, :retry_count
    add_index :archive_document_corrupted, :is_notify
    add_index :archive_document_corrupted, :user_id
  end
end