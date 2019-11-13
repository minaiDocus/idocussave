class AddFecAgirisToSoftwares < ActiveRecord::Migration[5.2]
  def change
  	add_column :softwares_settings, :is_fec_agiris_used, :boolean, default: false
    add_column :softwares_settings, :is_fec_agiris_auto_deliver, :integer, default: -1, null: false, limit: 4

    add_index :softwares_settings, :is_fec_agiris_used
  end
end
