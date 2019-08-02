class AddCegidToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :is_cegid_used, :boolean, default: false
    add_column :organizations, :is_cegid_auto_deliver, :boolean, default: false
  end
end
