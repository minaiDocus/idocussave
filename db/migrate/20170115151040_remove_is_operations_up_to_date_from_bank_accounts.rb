class RemoveIsOperationsUpToDateFromBankAccounts < ActiveRecord::Migration
  def change
    remove_column :bank_accounts, :is_operations_up_to_date, :string
  end
end
