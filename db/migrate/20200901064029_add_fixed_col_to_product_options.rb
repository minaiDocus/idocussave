class AddFixedColToProductOptions < ActiveRecord::Migration[5.2]
  def change
    add_column :product_option_orders, :freeze, :boolean, default: false, after: :is_to_be_disabled
  end
end
