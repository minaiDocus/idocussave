class AddColumnsToAnalyticReference < ActiveRecord::Migration
  def change
    add_column :analytic_references, :a1_references, :text, limit: 65535, after: :a1_name
    add_column :analytic_references, :a2_references, :text, limit: 65535, after: :a2_name
    add_column :analytic_references, :a3_references, :text, limit: 65535, after: :a3_name
  end
end
