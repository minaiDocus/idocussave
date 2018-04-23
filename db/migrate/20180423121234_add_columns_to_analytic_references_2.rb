class AddColumnsToAnalyticReferences2 < ActiveRecord::Migration
  def change
    add_column :analytic_references, :a1_ventilation, :decimal, precision: 5, scale: 2, default: 0, after: :a1_name
    add_column :analytic_references, :a2_ventilation, :decimal, precision: 5, scale: 2, default: 0, after: :a2_name
    add_column :analytic_references, :a3_ventilation, :decimal, precision: 5, scale: 2, default: 0, after: :a3_name
  end
end
