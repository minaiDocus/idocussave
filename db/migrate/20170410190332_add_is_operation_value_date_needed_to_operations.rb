class AddIsOperationValueDateNeededToOperations < ActiveRecord::Migration
  def change
    add_column :organizations, :is_operation_value_date_needed, :boolean, default: false
  end
end
