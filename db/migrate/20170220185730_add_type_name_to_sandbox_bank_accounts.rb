class AddTypeNameToSandboxBankAccounts < ActiveRecord::Migration
  def change
    add_column :sandbox_bank_accounts, :type_name, :string
  end
end
