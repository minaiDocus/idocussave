class AddIndexToSoftwaresSettings < ActiveRecord::Migration
  def change
    add_index :softwares_settings, :is_ibiza_used
    add_index :softwares_settings, :is_coala_used
    add_index :softwares_settings, :is_quadratus_used
    add_index :softwares_settings, :is_csv_descriptor_used
    add_index :softwares_settings, :is_exact_online_used
  end
end
