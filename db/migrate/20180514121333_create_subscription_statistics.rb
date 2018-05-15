class CreateSubscriptionStatistics < ActiveRecord::Migration
  def change
    create_table :subscription_statistics do |t|
      t.date    :month
      t.integer :organization_id
      t.string  :organization_code
      t.string  :organization_name
      t.text    :options
      t.text    :consumption
      t.text    :customers
      t.timestamps
    end
    add_index :subscription_statistics, :month
    add_index :subscription_statistics, :organization_code
  end
end
