class AddIdentifiedToBridgeAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :bridge_accounts, :identifier, :string
  end
end
