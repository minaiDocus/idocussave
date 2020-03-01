class AddIndexPackPiecesOrigin < ActiveRecord::Migration[5.2]
  def change
  	add_index :pack_pieces, :origin
  end
end
