class ChangeColumnsOfFtps < ActiveRecord::Migration
  def change
    change_table :ftps, bulk: true do |t|
      t.rename :host, :old_host
      t.column :encrypted_host, :string

      t.rename :login, :old_login
      t.column :encrypted_login, :string

      t.rename :password, :old_password
      t.column :encrypted_password, :string
    end
  end
end
