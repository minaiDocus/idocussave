class AddCurrencyToOperations < ActiveRecord::Migration
  def change
    add_column :operations, :currency, :text
  end
end
