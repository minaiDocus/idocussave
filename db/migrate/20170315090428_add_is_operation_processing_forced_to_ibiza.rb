class AddIsOperationProcessingForcedToIbiza < ActiveRecord::Migration
  def change
    add_column :ibizas, :is_operation_processing_forced, :boolean, default: false
  end
end
