class AddOriginalDocumentIdTempDocument < ActiveRecord::Migration[5.2]
  def change
    add_column :temp_documents, :parent_document_id, :integer, after: :is_an_original, null: true

    add_index :temp_documents, :parent_document_id
  end
end
