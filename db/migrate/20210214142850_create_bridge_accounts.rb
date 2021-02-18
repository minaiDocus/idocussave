class CreateBridgeAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :bridge_accounts do |t|
      t.string :encrypted_username
      t.string :entrycpted_password

      t.timestamps
    end
  end
end
