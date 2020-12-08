class CreateSoftwareIbizas < ActiveRecord::Migration[5.2]
  def change
    create_table :software_ibizas do |t|
      t.string :state
      t.string :state_2
      t.text :description
      t.string :description_separator
      t.text :piece_name_format
      t.string :piece_name_format_sep
      t.string :voucher_ref_target
      t.text :encrypted_access_token
      t.text :encrypted_access_token_2
      t.string :ibiza_id
      t.boolean :is_used
      t.integer :auto_deliver, default: -1
      t.references :owner, polymorphic: true
      t.boolean :is_auto_updating_accounting_plan, default: true
      t.integer :is_analysis_activated, default: -1
      t.integer :is_analysis_to_validate, default: -1

      t.timestamps
    end

    add_index :software_ibizas, :is_used
    add_index :software_ibizas, :ibiza_id
  end
end
