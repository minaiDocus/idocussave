class Add2ColumnsToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :dropbox_invalid_access_token, :boolean, default: true, after: :new_pre_assignment_available
    add_column :notifies, :dropbox_insufficient_space, :boolean, default: true, after: :dropbox_invalid_access_token
  end
end
