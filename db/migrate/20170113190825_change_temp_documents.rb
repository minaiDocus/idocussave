class ChangeTempDocuments < ActiveRecord::Migration
  def up
    change_table :temp_documents, bulk: true do |t|
      t.rename :fiduceo_id, :api_id
      t.rename :fiduceo_metadata, :retrieved_metadata
      t.rename :fiduceo_service_name, :retriever_service_name
      t.rename :fiduceo_custom_service_name, :retriever_name
      t.column :api_name, :string
      t.column :metadata, :text, limit: 16777215
      t.references :retriever, index: true, foreign_key: true
      t.index :user_id
      t.index :state
      t.index :is_an_original
      t.index :delivery_type
    end
  end

  def down
    change_table :temp_documents, bulk: true do |t|
      t.rename :api_id, :fiduceo_id
      t.rename :retrieved_metadata, :fiduceo_metadata
      t.rename :retriever_service_name, :fiduceo_service_name
      t.rename :retriever_name, :fiduceo_custom_service_name
      t.remove :api_name, :string
      t.remove :metadata, :text
      t.remove_references :retriever
      t.remove_index :user_id
      t.remove_index :state
      t.remove_index :is_an_original
      t.remove_index :delivery_type
    end
  end
end
