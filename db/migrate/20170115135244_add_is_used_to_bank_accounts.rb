class AddIsUsedToBankAccounts < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :is_used, :boolean, default: false
  end
end
