class AddIndexPackPiecesOrigin < ActiveRecord::Migration
  def change
  	add_index :pack_pieces, :origin
  end
end
