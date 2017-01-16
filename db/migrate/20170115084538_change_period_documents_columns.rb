class ChangePeriodDocumentsColumns < ActiveRecord::Migration
  def up
    change_table :period_documents, bulk: true do |t|
      t.rename :fiduceo_pieces, :retrieved_pieces
      t.rename :fiduceo_pages, :retrieved_pages
    end
  end

  def down
    change_table :period_documents, bulk: true do |t|
      t.rename :retrieved_pieces, :fiduceo_pieces
      t.rename :retrieved_pages, :fiduceo_pages
    end
  end
end
