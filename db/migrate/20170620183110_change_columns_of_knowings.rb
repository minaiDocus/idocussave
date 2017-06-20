class ChangeColumnsOfKnowings < ActiveRecord::Migration
  def change
    change_table :knowings, bulk: true do |t|
      t.rename :url, :old_url
      t.column :encrypted_url, :string

      t.rename :username, :old_username
      t.column :encrypted_username, :string

      t.rename :password, :old_password
      t.column :encrypted_password, :string
    end
  end
end
