class RemoveOldAttributesFromGoogleDocs < ActiveRecord::Migration
  def change
    change_table :google_docs, bulk: true do |t|
      t.remove :old_token
      t.remove :old_refresh_token
      t.remove :old_token_expires_at
    end
  end
end
