class ChangeColumnAmountFromPackReportPreseizures < ActiveRecord::Migration
  def up
    change_column :pack_report_preseizures, :amount, :decimal, precision: 11, scale: 2
  end

  def down
    change_column :pack_report_preseizures, :amount, :float
  end
end
