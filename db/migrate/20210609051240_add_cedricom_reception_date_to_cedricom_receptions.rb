class AddCedricomReceptionDateToCedricomReceptions < ActiveRecord::Migration[5.2]
  def change
    add_column :cedricom_receptions, :cedricom_reception_date, :date
  end
end
