class AddExactOnlineIdToPackReportPreseizure < ActiveRecord::Migration
  def change
    add_column :pack_report_preseizures, :exact_online_id, :string
  end
end
