class ChangeBankAccountsColumns < ActiveRecord::Migration
  def change
    rename_column :bank_accounts, :fiduceo_id, :api_id

    add_column :bank_accounts, :api_name, :string, default: 'budgea'
  end
end
