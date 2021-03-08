class DropTableBillingHistory < ActiveRecord::Migration[5.2]
  def change
    drop_table :billing_histories
  end
end
