class AddIbizaboxFolderIdToTempDocuments < ActiveRecord::Migration
  def change
    add_reference :temp_documents, :ibizabox_folder, index: true
  end
end
