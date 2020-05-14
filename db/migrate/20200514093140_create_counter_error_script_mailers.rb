class CreateCounterErrorScriptMailers < ActiveRecord::Migration[5.2]
  def change
    create_table :counter_error_script_mailers do |t|
      t.string :error_type
      t.integer :counter,   default: 0
      t.boolean :is_enable, default: true

      t.timestamps
    end
  end
end
