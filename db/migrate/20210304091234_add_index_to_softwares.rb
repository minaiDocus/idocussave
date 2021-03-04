class AddIndexToSoftwares < ActiveRecord::Migration[5.2]
  def change
    add_index :software_ibizas, :state
    add_index :software_ibizas, :state_2
    add_index :software_ibizas, :auto_deliver
    add_index :software_ibizas, :is_auto_updating_accounting_plan
    add_index :software_ibizas, :owner_id

    add_index :software_exact_online, :state
    add_index :software_exact_online, :is_used
    add_index :software_exact_online, :auto_deliver
    add_index :software_exact_online, :owner_id

    add_index :software_coalas, :auto_deliver
    add_index :software_coalas, :owner_id

    add_index :software_quadratus, :auto_deliver
    add_index :software_quadratus, :owner_id

    add_index :software_csv_descriptors, :auto_deliver
    add_index :software_csv_descriptors, :owner_id
    add_index :software_csv_descriptors, :use_own_csv_descriptor_format

    add_index :software_cegids, :auto_deliver
    add_index :software_cegids, :owner_id

    add_index :software_fec_agiris, :owner_id
    add_index :software_fec_agiris, :auto_deliver
  end
end
