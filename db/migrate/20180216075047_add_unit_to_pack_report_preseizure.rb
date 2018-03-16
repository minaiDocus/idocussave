class AddUnitToPackReportPreseizure < ActiveRecord::Migration
  def change
    add_column :pack_report_preseizures, :unit, :string, limit: 5, default: "EUR", after: :currency
  end
end
