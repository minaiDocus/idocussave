class CreatePackReportTempPreseizures < ActiveRecord::Migration[5.2]
  def change
    create_table :pack_report_temp_preseizures do |t|
      t.integer :position
      t.boolean :is_made_by_abbyy, default: false, null: false
      t.integer :organization_id
      t.integer :user_id
      t.integer :report_id
      t.integer :piece_id
      t.integer :operation_id
      t.string :state, default: 'created'
      t.json :raw_preseizure

      t.timestamps
    end

    add_index :pack_report_temp_preseizures, :operation_id
    add_index :pack_report_temp_preseizures, :organization_id
    add_index :pack_report_temp_preseizures, :piece_id
    add_index :pack_report_temp_preseizures, :position
    add_index :pack_report_temp_preseizures, :report_id
    add_index :pack_report_temp_preseizures, :user_id
  end
end