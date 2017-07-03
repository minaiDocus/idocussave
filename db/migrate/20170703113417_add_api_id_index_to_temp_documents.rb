class AddApiIdIndexToTempDocuments < ActiveRecord::Migration
  def change
    add_index :temp_documents, :api_id
  end
end
