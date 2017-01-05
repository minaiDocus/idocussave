class AddIndexToOperations < ActiveRecord::Migration
  def change
    add_index :operations, [:fiduceo_id], name: :fiduceo_id, using: :btree
  end
end
