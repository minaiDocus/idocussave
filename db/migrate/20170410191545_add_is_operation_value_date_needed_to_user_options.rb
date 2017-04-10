class AddIsOperationValueDateNeededToUserOptions < ActiveRecord::Migration
  def change
    add_column :user_options, :is_operation_value_date_needed, :integer, limit: 4, default: -1, null: false
  end
end
