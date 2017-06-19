class ChangeColumnsOfGoogleDocs < ActiveRecord::Migration
  def change
    change_table :google_docs, bulk: true do |t|
      t.rename :token, :old_token
      t.column :encrypted_access_token, :string

      t.rename :refresh_token, :old_refresh_token
      t.column :encrypted_refresh_token, :string

      t.rename :token_expires_at, :old_token_expires_at
      t.column :encrypted_access_token_expires_at, :string
    end
  end
end
