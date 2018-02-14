class AddCurrencyToAccountBookType < ActiveRecord::Migration
  def change
    add_column :account_book_types, :currency, :string, default: "EUR", limit: 5, after: :entry_type
  end
end