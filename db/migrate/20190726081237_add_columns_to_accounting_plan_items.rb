class AddColumnsToAccountingPlanItems < ActiveRecord::Migration
  def change
    add_column :accounting_plan_items, :updated_at, :datetime
    add_column :accounting_plan_items, :created_at, :datetime
    add_column :accounting_plan_items, :is_updated, :boolean, default: true

    add_index :accounting_plan_items, :is_updated
  end
end
