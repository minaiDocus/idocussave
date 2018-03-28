class DropNotifiesPreAssignmentDeliveries < ActiveRecord::Migration
  def change
    drop_table :notifies_pre_assignment_deliveries do |t|
      t.belongs_to :notify
      t.belongs_to :pre_assignment_delivery

      t.index [:notify_id, :pre_assignment_delivery_id], name: 'index_notify_id_pre_assignment_delivery_id'
    end
  end
end
