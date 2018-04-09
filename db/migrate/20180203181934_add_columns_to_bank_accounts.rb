class AddColumnsToBankAccounts < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :lock_old_operation, :boolean, default: true
    add_column :bank_accounts, :permitted_late_days, :integer, default: 30
  end
end
