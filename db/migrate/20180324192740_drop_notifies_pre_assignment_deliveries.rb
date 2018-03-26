class DropNotifiesPreAssignmentDeliveries < ActiveRecord::Migration
  def change
    drop_table :notifies_pre_assignment_deliveries
  end
end
