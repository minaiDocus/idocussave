class AddIsUpdatingToAccountingPlan < ActiveRecord::Migration
  def change
    add_column :accounting_plans, :is_updating, :boolean, default: false
  end
end
