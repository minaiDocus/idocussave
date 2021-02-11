class CreateBillingHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :billing_histories do |t|
      t.integer :value_period
      t.decimal :amount
      t.string :state
      t.references :user
      t.references :period

      t.timestamps
    end

    add_index :billing_histories, :value_period
    add_index :billing_histories, :state
  end
end
