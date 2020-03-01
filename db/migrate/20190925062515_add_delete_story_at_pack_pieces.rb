class AddDeleteStoryAtPackPieces < ActiveRecord::Migration[5.2]
  def change
  	add_column :pack_pieces, :delete_at, :datetime
    add_column :pack_pieces, :delete_by, :string

    add_index :pack_pieces, :delete_at
    add_index :pack_pieces, :delete_by
  end
end