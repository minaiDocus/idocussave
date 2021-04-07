class CreateStaffingFlow < ActiveRecord::Migration[5.2]
  def change
    create_table :staffing_flows do |t|
      t.datetime :created_at
      t.datetime :updated_at
      t.string   :kind
      t.text     :params, limit: 4294967295
      t.string   :state
    end

    add_index :staffing_flows, :kind
    add_index :staffing_flows, :state
  end
end