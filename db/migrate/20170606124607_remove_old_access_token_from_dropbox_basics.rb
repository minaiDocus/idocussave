class RemoveOldAccessTokenFromDropboxBasics < ActiveRecord::Migration
  def change
    remove_column :dropbox_basics, :old_access_token, :string
  end
end
