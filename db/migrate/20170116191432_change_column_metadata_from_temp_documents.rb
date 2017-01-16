class ChangeColumnMetadataFromTempDocuments < ActiveRecord::Migration
  def change
    change_column :temp_documents, :metadata, :text, limit: 16777215
  end
end
