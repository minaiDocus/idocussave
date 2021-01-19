class AddIndexToPiece < ActiveRecord::Migration[5.2]
  def change
    add_index :pack_pieces, :pre_assignment_state
  end
end
