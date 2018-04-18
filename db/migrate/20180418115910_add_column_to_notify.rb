class AddColumnToNotify < ActiveRecord::Migration
  def change
    add_column :notifies, :pre_assignment_ignored_piece, :boolean, default: false
    add_column :notifies, :pre_assignment_ignored_piece_count, :integer, default: 0
  end
end
