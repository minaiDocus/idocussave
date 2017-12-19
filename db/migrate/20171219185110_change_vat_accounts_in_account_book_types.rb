class ChangeVatAccountsInAccountBookTypes < ActiveRecord::Migration
  def change
    remove_column :account_book_types, :vat_account_20, :string, after: :vat_account
    add_column :account_book_types, :vat_account_8_5, :string, after: :vat_account_10
  end
end
