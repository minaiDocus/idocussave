class RemoveSignatureFromTempDocuments < ActiveRecord::Migration
  def change
    remove_column :temp_documents, :signature, :string
  end
end
