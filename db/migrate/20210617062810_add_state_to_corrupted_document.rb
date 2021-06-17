class AddStateToCorruptedDocument < ActiveRecord::Migration[5.2]
  def change
  	add_column :archive_document_corrupted, :state, :string, after: :fingerprint, default: 'ready', null: false
  	add_column :archive_document_corrupted, :error_message, :text, limit: 4294967295, after: :state

    add_index :archive_document_corrupted, :state
  end
end
