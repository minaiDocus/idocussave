class RemoveOldFieldsFromPreAssignmentDeliveries < ActiveRecord::Migration
  def up
    change_table :pre_assignment_deliveries, bulk: true do |t|
      t.remove :mongo_id
      t.remove :organization_id_mongo_id
      t.remove :report_id_mongo_id
      t.remove :user_id_mongo_id
    end
  end

  def down
    change_table :pre_assignment_deliveries, bulk: true do |t|
      t.column :mongo_id, :string
      t.column :organization_id_mongo_id, :string
      t.column :report_id_mongo_id, :string
      t.column :user_id_mongo_id, :string
    end
  end
end
