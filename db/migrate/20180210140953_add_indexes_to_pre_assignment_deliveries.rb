class AddIndexesToPreAssignmentDeliveries < ActiveRecord::Migration
  def change
    add_index :pre_assignment_deliveries, :pack_name
    add_index :pre_assignment_deliveries, :state
    add_index :pre_assignment_deliveries, :is_auto
    add_index :pre_assignment_deliveries, :total_item
    add_index :pre_assignment_deliveries, :is_to_notify
    add_index :pre_assignment_deliveries, :is_notified
  end
end
