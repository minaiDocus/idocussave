class AddIdoXPackageToSubscription < ActiveRecord::Migration[5.2]
  def change
  	add_column :subscriptions, :is_idox_package_active, :boolean, after: :is_basic_package_active, default: false
  	add_column :subscriptions, :is_idox_package_to_be_disabled, :boolean, after: :is_basic_package_to_be_disabled, default: false

  	add_index :subscriptions, :is_idox_package_active
  end
end
