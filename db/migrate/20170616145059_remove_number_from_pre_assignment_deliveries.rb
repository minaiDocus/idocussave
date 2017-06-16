class RemoveNumberFromPreAssignmentDeliveries < ActiveRecord::Migration
  def change
    remove_column :pre_assignment_deliveries, :number, :integer
  end
end
