class AddColumnsToUserOptions < ActiveRecord::Migration
  def change
    add_column :user_options, :skip_accounting_plan_finder, :boolean, default: false
  end
end
