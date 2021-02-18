class FixTypoInBridgeAccount < ActiveRecord::Migration[5.2]
  def change
    rename_column :bridge_accounts, :entrycpted_password, :encrypted_password
  end
end
