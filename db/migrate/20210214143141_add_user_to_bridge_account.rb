class AddUserToBridgeAccount < ActiveRecord::Migration[5.2]
  def change
    add_reference :bridge_accounts, :user
  end
end
