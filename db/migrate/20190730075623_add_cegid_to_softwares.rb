class AddCegidToSoftwares < ActiveRecord::Migration
  def change
    add_column :softwares_settings, :is_cegid_used, :boolean, default: false
    add_column :softwares_settings, :is_cegid_auto_deliver, :integer, default: -1, null: false, limit: 4

    add_index :softwares_settings, :is_cegid_used
  end
end
