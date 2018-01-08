class AddColumnsToAnalyticReferences < ActiveRecord::Migration
  def change
    change_table :analytic_references do |t|
      t.rename :name, :a1_name
      t.rename :axis1, :a1_axis1
      t.rename :axis2, :a1_axis2
      t.rename :axis3, :a1_axis3

      t.column :a2_name, :string
      t.column :a2_axis1, :string
      t.column :a2_axis2, :string
      t.column :a2_axis3, :string

      t.column :a3_name, :string
      t.column :a3_axis1, :string
      t.column :a3_axis2, :string
      t.column :a3_axis3, :string
    end
  end
end
