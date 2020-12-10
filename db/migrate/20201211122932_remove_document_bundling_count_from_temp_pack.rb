class RemoveDocumentBundlingCountFromTempPack < ActiveRecord::Migration[5.2]
  def change
    remove_column :temp_packs, :document_bundling_count, :integer
  end
end
