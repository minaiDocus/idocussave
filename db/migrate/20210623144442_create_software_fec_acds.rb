class CreateSoftwareFecAcds < ActiveRecord::Migration[5.2]
  def change
    create_table :software_fec_acds do |t|
      t.boolean :is_used
      t.integer :auto_deliver
      t.references :owner, polymorphic: true

      t.timestamps
    end

    add_index :software_fec_acds, :is_used
    add_index :software_fec_acds, :owner_id
    add_index :software_fec_acds, :auto_deliver
  end
end
