class AddDefaultBankingProviderToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :default_banking_provider, :string
  end
end
