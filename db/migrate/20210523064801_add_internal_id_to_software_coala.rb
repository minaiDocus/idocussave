class AddInternalIdToSoftwareCoala < ActiveRecord::Migration[5.2]
  def change
    add_column :software_coalas, :internal_id, :string
  end
end
