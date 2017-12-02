class RemoveOldColumnsFromEvents < ActiveRecord::Migration
  def change
    remove_column :events, :mongo_id, :string
    remove_column :events, :organization_id_mongo_id, :string
    remove_column :events, :user_id_mongo_id, :string
    remove_column :events, :number, :integer
  end
end
