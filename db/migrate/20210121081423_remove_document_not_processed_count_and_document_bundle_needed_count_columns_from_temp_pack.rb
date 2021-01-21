class RemoveDocumentNotProcessedCountAndDocumentBundleNeededCountColumnsFromTempPack < ActiveRecord::Migration[5.2]
  def change
    remove_column :temp_packs, :document_not_processed_count, :integer
    remove_column :temp_packs, :document_bundle_needed_count, :integer
  end
end
