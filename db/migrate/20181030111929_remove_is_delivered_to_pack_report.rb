class RemoveIsDeliveredToPackReport < ActiveRecord::Migration
  def up
    change_table :pack_reports, bulk: true do |t|
      t.remove :is_delivered
    end
  end

  def down
    change_table :pack_reports, bulk: true do |t|
      t.column :is_delivered, :boolean, default: false, null: false, after: :type
    end
  end
end
