class AddPreAssignmentStateToPiece < ActiveRecord::Migration
  def change
    add_column :pack_pieces, :pre_assignment_state, :string, default: 'ready', after: :is_awaiting_pre_assignment
  end
end
