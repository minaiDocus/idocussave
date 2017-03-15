class AddIsOperationProcessingForcedToUserOption < ActiveRecord::Migration
  def change
    add_column :user_options, :is_operation_processing_forced, :integer, limit: 4, default: -1, null: false
  end
end
