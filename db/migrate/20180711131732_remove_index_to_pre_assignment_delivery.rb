class RemoveIndexToPreAssignmentDelivery < ActiveRecord::Migration
  def change
    remove_index :pre_assignment_deliveries, :pack_name
    remove_index :pre_assignment_deliveries, :total_item
  end
end
