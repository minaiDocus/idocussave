class ChangeDropboxIdSize < ActiveRecord::Migration
  def change
    change_column :dropbox_basics, :dropbox_id, :bigint
  end
end
