class CreateConnectors < ActiveRecord::Migration
  def change
    create_table :connectors do |t|
      t.string :name
      t.text :capabilities
      t.text :apis
      t.text :active_apis
      t.integer :budgea_id
      t.string :fiduceo_ref
      t.text :combined_fields

      t.timestamps
    end
  end
end
