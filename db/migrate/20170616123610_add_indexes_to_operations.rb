class AddIndexesToOperations < ActiveRecord::Migration
  def change
    change_table :operations, bulk: true do |t|
      t.index :created_at
      t.index :processed_at
      t.index :is_locked
      t.index :forced_processing_at
      t.index :deleted_at
    end
  end
end
