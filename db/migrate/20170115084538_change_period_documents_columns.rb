class ChangePeriodDocumentsColumns < ActiveRecord::Migration
  def change
    rename_column :period_documents, :fiduceo_pieces, :retrieved_pieces
    rename_column :period_documents, :fiduceo_pages, :retrieved_pages
  end
end
