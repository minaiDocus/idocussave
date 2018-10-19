class AddColumnToPackReportPreseizures < ActiveRecord::Migration
  def change
    add_column :pack_report_preseizures, :is_delivered_to, :string, default: ''
  end
end
