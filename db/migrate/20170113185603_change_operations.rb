class ChangeOperations < ActiveRecord::Migration
  def up
    change_table :operations, bulk: true do |t|
      t.rename :fiduceo_id, :api_id
      t.column :api_name, :string, default: 'budgea'
      t.column :type_name, :string
      t.index :api_name
    end
  end

  def down
    change_table :operations, bulk: true do |t|
      t.rename :api_id, :fiduceo_id
      t.remove :api_name, :string
      t.remove :type_name, :string
      t.remove_index :api_name
    end
  end
end
