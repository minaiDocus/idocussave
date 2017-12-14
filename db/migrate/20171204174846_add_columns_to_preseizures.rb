class AddColumnsToPreseizures < ActiveRecord::Migration
  def change
    change_table :pack_report_preseizures, bulk: true do |t|
      t.column :similar_preseizure_id, :integer
      t.column :duplicate_detected_at, :datetime
      t.column :is_blocked_for_duplication, :boolean, default: false
      t.column :marked_as_duplicate_at, :datetime
      t.column :marked_as_duplicate_by_user_id, :integer
      t.column :duplicate_unblocked_at, :datetime
      t.column :duplicate_unblocked_by_user_id, :integer

      t.index :similar_preseizure_id
      t.index :is_blocked_for_duplication
      t.index :marked_as_duplicate_by_user_id
      t.index :duplicate_unblocked_by_user_id
    end
  end
end
