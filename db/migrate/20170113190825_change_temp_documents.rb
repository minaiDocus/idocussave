class ChangeTempDocuments < ActiveRecord::Migration
  def change
    rename_column :temp_documents, :fiduceo_id, :api_id
    rename_column :temp_documents, :fiduceo_metadata, :retrieved_metadata
    rename_column :temp_documents, :fiduceo_service_name, :retriever_service_name
    rename_column :temp_documents, :fiduceo_custom_service_name, :retriever_name

    add_column :temp_documents, :api_name, :string
    add_column :temp_documents, :metadata, :string

    add_reference :temp_documents, :retriever

    add_index :temp_documents, :user_id
    add_index :temp_documents, :retriever_id
    add_index :temp_documents, :api_id
    add_index :temp_documents, :state
    add_index :temp_documents, :is_an_original
    add_index :temp_documents, :delivery_type
  end
end
