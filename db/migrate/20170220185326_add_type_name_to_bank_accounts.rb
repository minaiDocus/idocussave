class AddTypeNameToBankAccounts < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :type_name, :string
  end
end
