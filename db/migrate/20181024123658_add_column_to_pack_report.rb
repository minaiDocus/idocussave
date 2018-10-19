class AddColumnToPackReport < ActiveRecord::Migration
  def change
    add_column :pack_reports, :is_delivered_to, :string, default: ''
  end
end
