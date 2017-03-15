class AddIsOperationProcessingForcedToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :is_operation_processing_forced, :boolean, default: false
  end
end
