class CreateSoftwareFecAgiris < ActiveRecord::Migration[5.2]
  def change
    create_table :software_fec_agiris do |t|
      t.boolean :is_used
      t.integer :auto_deliver, default: -1
      t.references :owner, polymorphic: true

      t.timestamps
    end

    add_index :software_fec_agiris, :is_used
  end
end
