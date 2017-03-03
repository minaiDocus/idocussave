class AddDeletedAtToOperations < ActiveRecord::Migration
  def change
    add_column :operations, :deleted_at, :datetime
  end
end
