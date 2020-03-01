class RemoveStampFromSubscription < ActiveRecord::Migration[5.2]
  def change
    remove_column :subscriptions, :is_stamp_active, :boolean
    remove_column :subscriptions, :is_stamp_to_be_disabled, :boolean
  end
end
