class RemoveDropboxExtendedAccessTokenFromSettings < ActiveRecord::Migration
  def change
    remove_column :settings, :dropbox_extended_access_token, :text
  end
end
