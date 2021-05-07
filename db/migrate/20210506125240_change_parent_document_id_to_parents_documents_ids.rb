class ChangeParentDocumentIdToParentsDocumentsIds < ActiveRecord::Migration[5.2]
  def change
  	add_column :temp_documents, :parents_documents_ids, :text, array: true, after: :parents_documents_pages

  	TempDocument.where('parent_document_id > 0').each do |temp_document|
      temp_document.parents_documents_ids = [temp_document.parent_document_id]
      temp_document.save
    end

    # remove_column :temp_documents, :parent_document_id # TODO ... UNCOMMENT IF NECESSARY
  end
end
