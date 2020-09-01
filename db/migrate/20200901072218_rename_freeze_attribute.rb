class RenameFreezeAttribute < ActiveRecord::Migration[5.2]
  def change
  	remove_column :product_option_orders, :freeze, :boolean
  	add_column :product_option_orders, :is_frozen, :boolean, default: false, after: :is_to_be_disabled
  end
end
