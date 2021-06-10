class CreateCedricomReceptions < ActiveRecord::Migration[5.2]
  def change
    create_table :cedricom_receptions do |t|
      t.references :bank_account
      t.integer :cedricom_id

      t.timestamps
    end
  end
end
