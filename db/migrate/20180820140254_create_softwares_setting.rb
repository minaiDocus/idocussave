class CreateSoftwaresSetting < ActiveRecord::Migration
  def change
    create_table :softwares_settings do |t|
      t.integer :user_id
      t.boolean :is_ibiza_used,                                 default: false
      t.integer :is_ibiza_auto_deliver,               limit: 4, default: -1,    null: false
      t.integer :is_ibiza_compta_analysis_activated,  limit: 4, default: -1,    null: false
      t.boolean :is_coala_used,                                 default: false
      t.integer :is_coala_auto_deliver,               limit: 4, default: -1,    null: false
      t.boolean :is_quadratus_used,                             default: false
      t.integer :is_quadratus_auto_deliver,           limit: 4, default: -1,    null: false
      t.boolean :is_csv_descriptor_used,                        default: false
      t.boolean :use_own_csv_descriptor_format,                 default: false
      t.integer :is_csv_descriptor_auto_deliver,      limit: 4, default: -1,    null: false
    end
  end
end