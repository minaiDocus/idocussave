class RemoveIsDeliveredToPackReportPreseizure < ActiveRecord::Migration
  def up
    change_table :pack_report_preseizures, bulk: true do |t|
      t.remove :is_delivered
    end
  end

  def down
    change_table :pack_report_preseizures, bulk: true do |t|
      t.column :is_delivered, :boolean, default: false, null: false, after: :is_made_by_abbyy
    end
  end
end
