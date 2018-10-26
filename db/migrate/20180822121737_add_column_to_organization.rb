class AddColumnToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :is_quadratus_auto_deliver, :boolean, default: false, after: :is_quadratus_used
    add_column :organizations, :is_coala_auto_deliver, :boolean, default: false, after: :is_coala_used
    add_column :organizations, :is_csv_descriptor_auto_deliver, :boolean, default: false, after: :is_csv_descriptor_used
  end
end
