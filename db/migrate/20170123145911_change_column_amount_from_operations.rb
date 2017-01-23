class ChangeColumnAmountFromOperations < ActiveRecord::Migration
  def up
    change_column :operations, :amount, :decimal, precision: 11, scale: 2
  end

  def down
    change_column :operations, :amount, :float
  end
end
