class AddParentDocumentPagesToNewTempDocument < ActiveRecord::Migration[5.2]
  def change
    add_column :temp_documents, :parents_documents_pages, :text, array: true, after: :parent_document_id
  end
end
