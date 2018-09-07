class AddIndexToPackPiece < ActiveRecord::Migration
  def change
    add_index :pack_pieces, :name
  end
end
