class AddSkippedOperationCountToCedricomReception < ActiveRecord::Migration[5.2]
  def change
    add_column :cedricom_receptions, :skipped_operations_count, :integer
  end
end
