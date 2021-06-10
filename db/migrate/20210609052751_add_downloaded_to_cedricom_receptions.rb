class AddDownloadedToCedricomReceptions < ActiveRecord::Migration[5.2]
  def change
    add_column :cedricom_receptions, :downloaded, :boolean
  end
end
