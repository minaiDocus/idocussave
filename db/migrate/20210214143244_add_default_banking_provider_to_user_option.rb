class AddDefaultBankingProviderToUserOption < ActiveRecord::Migration[5.2]
  def change
    add_column :user_options, :default_banking_provider, :string
  end
end
