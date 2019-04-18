class FixIndexOfPackReportPreseizures < ActiveRecord::Migration[5.2]
  def change
    change_column :pack_report_preseizures, :operation_label, :text, limit: 65535

    remove_index :pack_report_preseizures, :mongo_id
    remove_index :pack_report_preseizures, name: 'operation_id_mongo_id'
    remove_index :pack_report_preseizures, name: 'organization_id_mongo_id'
    remove_index :pack_report_preseizures, name: 'piece_id_mongo_id'
    remove_index :pack_report_preseizures, name: 'report_id_mongo_id'
    remove_index :pack_report_preseizures, name: 'user_id_mongo_id'

    add_index    :pack_report_preseizures, :position
    add_index    :pack_report_preseizures, :third_party
  end
end
