class AddNewScannedDocumentsToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :new_scanned_documents, :boolean, default: false, after: :unblocked_preseizure_count
  end
end
