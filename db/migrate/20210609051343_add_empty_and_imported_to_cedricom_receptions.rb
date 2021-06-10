class AddEmptyAndImportedToCedricomReceptions < ActiveRecord::Migration[5.2]
  def change
    add_column :cedricom_receptions, :empty, :boolean
    add_column :cedricom_receptions, :imported, :boolean
  end
end
