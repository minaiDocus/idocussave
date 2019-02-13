class AddIndexToPreseizureAndPiece < ActiveRecord::Migration
  def change
    add_index :pack_report_preseizures, :updated_at
    add_index :pack_pieces, :updated_at
  end
end
