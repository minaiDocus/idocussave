class AddColumnToPreAssignmentDeliveries < ActiveRecord::Migration
  def change
    add_column    :pre_assignment_deliveries, :deliver_to, :string, default: 'ibiza'
    rename_column :pre_assignment_deliveries, :ibiza_id, :software_id
    rename_column :pre_assignment_deliveries, :xml_data, :data_to_deliver

    add_index     :pre_assignment_deliveries, :deliver_to
  end
end
