class AddIsDeliveryActivatedToMcfSettings < ActiveRecord::Migration
  def change
    add_column :mcf_settings, :is_delivery_activated, :boolean, default: true
  end
end
