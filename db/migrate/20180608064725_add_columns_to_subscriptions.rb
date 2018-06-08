class AddColumnsToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :is_mini_package_active, :boolean, default: false, null: false, after: :is_micro_package_active
    add_column :subscriptions, :is_mini_package_to_be_disabled, :boolean, after: :is_micro_package_to_be_disabled
  end
end
