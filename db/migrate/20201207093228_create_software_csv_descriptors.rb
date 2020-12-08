class CreateSoftwareCsvDescriptors < ActiveRecord::Migration[5.2]
  def change
    create_table :software_csv_descriptors do |t|
      t.boolean :is_used
      t.integer :auto_deliver, default: -1
      t.references :owner, polymorphic: true
      t.boolean :comma_as_number_separator
      t.boolean :use_own_csv_descriptor_format
      t.text :directive

      t.timestamps
    end

    add_index :software_csv_descriptors, :is_used
  end
end
