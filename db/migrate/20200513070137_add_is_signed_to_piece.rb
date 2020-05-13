class AddIsSignedToPiece < ActiveRecord::Migration[5.2]
  def change
    add_column :pack_pieces, :is_signed, :boolean, after: :is_a_cover, default: false
  end
end
