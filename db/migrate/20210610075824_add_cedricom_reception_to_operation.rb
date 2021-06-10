class AddCedricomReceptionToOperation < ActiveRecord::Migration[5.2]
  def change
    add_reference :operations, :cedricom_reception, foreign_key: true
  end
end
