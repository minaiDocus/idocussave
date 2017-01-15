class AddIndexToPackPieces < ActiveRecord::Migration
  def change
    add_index :pack_pieces, :number, unique: true
  end
end
