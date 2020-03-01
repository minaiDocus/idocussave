class ChangeDropboxIdSize < ActiveRecord::Migration[5.2]
  def change
    change_column :dropbox_basics, :dropbox_id, :bigint
  end
end
