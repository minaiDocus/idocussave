class ChangeOperations < ActiveRecord::Migration
  def change
    rename_column :operations, :fiduceo_id, :api_id
    add_column :operations, :api_name, :string, default: 'budgea'
    add_column :operations, :type_name, :string

    remove_index :operations, name: :fiduceo_id
    add_index :operations, :api_id
    add_index :operations, :api_name
    add_index :operations, :user_id
    add_index :operations, :bank_account_id
  end
end
