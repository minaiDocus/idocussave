class AddColumnsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :is_exact_online_used, :boolean, default: false
    add_column :organizations, :is_exact_online_auto_deliver, :boolean, default: false
  end
end
