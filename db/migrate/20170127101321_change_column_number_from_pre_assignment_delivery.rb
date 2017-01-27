class ChangeColumnNumberFromPreAssignmentDelivery < ActiveRecord::Migration
  def up
    change_column :pre_assignment_deliveries, :number, :integer
  end

  def down
    change_column :pre_assignment_deliveries, :number, :string, limit: 255
  end
end
