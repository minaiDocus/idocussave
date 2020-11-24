class AddVatAccountsToAccountBookType < ActiveRecord::Migration[5.2]
  def change
    add_column :account_book_types, :vat_accounts, :text, after: :default_charge_account
  end
end
