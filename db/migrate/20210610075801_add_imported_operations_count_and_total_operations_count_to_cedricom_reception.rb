class AddImportedOperationsCountAndTotalOperationsCountToCedricomReception < ActiveRecord::Migration[5.2]
  def change
    add_column :cedricom_receptions, :imported_operations_count, :integer
    add_column :cedricom_receptions, :total_operations_count, :integer
  end
end
