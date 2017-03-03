class AddColumnsToOperations < ActiveRecord::Migration
  def change
    change_table :operations, bulk: true do |t|
      t.column :forced_processing_at, :datetime
      t.column :forced_processing_by_user_id, :integer
    end
  end
end
