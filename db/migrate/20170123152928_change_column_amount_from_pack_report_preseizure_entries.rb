class ChangeColumnAmountFromPackReportPreseizureEntries < ActiveRecord::Migration
  def up
    change_column :pack_report_preseizure_entries, :amount, :decimal, precision: 11, scale: 2
  end

  def down
    change_column :pack_report_preseizure_entries, :amount, :float
  end
end
