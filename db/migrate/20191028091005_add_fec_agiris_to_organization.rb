class AddFecAgirisToOrganization < ActiveRecord::Migration[5.2]
  def change
  	add_column :organizations, :is_fec_agiris_used, :boolean, default: false
    add_column :organizations, :is_fec_agiris_auto_deliver, :boolean, default: false
  end
end
