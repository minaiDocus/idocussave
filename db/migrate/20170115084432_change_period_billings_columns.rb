class ChangePeriodBillingsColumns < ActiveRecord::Migration
  def change
    rename_column :period_billings, :fiduceo_pieces, :retrieved_pieces
    rename_column :period_billings, :fiduceo_pages, :retrieved_pages
  end
end
