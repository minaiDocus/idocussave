class RemoveIsOperationProcessingForcedFromIbiza < ActiveRecord::Migration
  def change
    remove_column :ibizas, :is_operation_processing_forced, :boolean
  end
end
