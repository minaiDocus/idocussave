class AddColumnsToBankAccount < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :original_currency, :text, after: :journal
    add_column :bank_accounts, :currency, :string, default: "EUR", limit: 5, after: :journal
  end
end
