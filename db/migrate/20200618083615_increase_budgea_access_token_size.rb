class IncreaseBudgeaAccessTokenSize < ActiveRecord::Migration[5.2]
  def change
  	change_column :budgea_accounts, :encrypted_access_token, :text
  end
end
