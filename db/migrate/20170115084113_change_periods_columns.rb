class ChangePeriodsColumns < ActiveRecord::Migration
  def change
    rename_column :periods, :fiduceo_pieces, :retrieved_pieces
    rename_column :periods, :fiduceo_pages, :retrieved_pages
  end
end
