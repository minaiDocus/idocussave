class AddPagesNumberToPiece < ActiveRecord::Migration
  def change
    add_column :pack_pieces, :pages_number, :integer, default: 0, after: :position
  end
end
