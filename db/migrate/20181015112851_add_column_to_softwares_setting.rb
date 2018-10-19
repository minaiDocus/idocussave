class AddColumnToSoftwaresSetting < ActiveRecord::Migration
  def change
    add_column :softwares_settings, :is_exact_online_used, :boolean, default: false
    add_column :softwares_settings, :is_exact_online_auto_deliver, :integer, limit: 4, default: -1, null: false
  end
end
