class ChangeTypeOfAccessTokenFromGoogleDocs < ActiveRecord::Migration[5.2]
  def change
    change_column :google_docs, :encrypted_access_token, :text
    change_column :google_docs, :encrypted_refresh_token, :text
    change_column :google_docs, :encrypted_access_token_expires_at, :text
  end
end
