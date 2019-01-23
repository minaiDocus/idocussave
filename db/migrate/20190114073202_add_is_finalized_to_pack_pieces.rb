class AddIsFinalizedToPackPieces < ActiveRecord::Migration
  def change
    add_column :pack_pieces, :is_finalized, :boolean, default: false
    add_index  :pack_pieces, :is_finalized
  end
end
