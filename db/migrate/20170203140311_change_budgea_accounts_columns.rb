class ChangeBudgeaAccountsColumns < ActiveRecord::Migration
  def change
    change_table :budgea_accounts, bulk: true do |t|
      t.rename :access_token, :old_access_token
      t.column :encrypted_access_token, :string
    end
  end
end
