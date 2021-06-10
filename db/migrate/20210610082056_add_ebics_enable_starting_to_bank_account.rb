class AddEbicsEnableStartingToBankAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :bank_accounts, :ebics_enabled_starting, :date
  end
end
