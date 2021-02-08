class AddIsToBeDisableColumnsToBankAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :bank_accounts, :is_to_be_disabled, :boolean, default: false, after: :is_used
  end
end
