class ChangeDropboxBasicsColumns < ActiveRecord::Migration
  def change
    change_table :dropbox_basics, bulk: true do |t|
      t.rename :access_token, :old_access_token
      t.column :encrypted_access_token, :string
    end
  end
end
