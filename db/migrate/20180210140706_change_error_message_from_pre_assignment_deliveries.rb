class ChangeErrorMessageFromPreAssignmentDeliveries < ActiveRecord::Migration
  def up
    change_column :pre_assignment_deliveries, :error_message, :text
  end

  def down
    change_column :pre_assignment_deliveries, :error_message, :string
  end
end
