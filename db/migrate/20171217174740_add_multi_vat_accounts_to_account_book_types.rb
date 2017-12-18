class AddMultiVatAccountsToAccountBookTypes < ActiveRecord::Migration
  def change
    change_table :account_book_types, bulk: true do |t|
      t.column :vat_account_20,  :string, after: :vat_account
      t.column :vat_account_10,  :string, after: :vat_account_20
      t.column :vat_account_5_5, :string, after: :vat_account_10
      t.column :vat_account_2_1, :string, after: :vat_account_5_5
    end
  end
end
