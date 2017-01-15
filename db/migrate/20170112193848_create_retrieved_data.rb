class CreateRetrievedData < ActiveRecord::Migration
  def change
    create_table :retrieved_data do |t|
      t.text :state
      t.text :content
      t.string :error_message
      t.text :processed_connection_ids

      t.timestamps null: false
    end

    add_reference :retrieved_data, :user, foreign_key: true
  end
end
