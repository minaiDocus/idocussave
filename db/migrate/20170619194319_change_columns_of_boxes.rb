class ChangeColumnsOfBoxes < ActiveRecord::Migration
  def change
    change_table :boxes, bulk: true do |t|
      t.rename :access_token, :old_access_token
      t.column :encrypted_access_token, :string

      t.rename :refresh_token, :old_refresh_token
      t.column :encrypted_refresh_token, :string
    end
  end
end
