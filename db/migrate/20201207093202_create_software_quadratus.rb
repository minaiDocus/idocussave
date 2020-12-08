class CreateSoftwareQuadratus < ActiveRecord::Migration[5.2]
  def change
    create_table :software_quadratus do |t|
      t.boolean :is_used
      t.integer :auto_deliver, default: -1
      t.references :owner, polymorphic: true

      t.timestamps
    end

    add_index :software_quadratus, :is_used
  end
end
