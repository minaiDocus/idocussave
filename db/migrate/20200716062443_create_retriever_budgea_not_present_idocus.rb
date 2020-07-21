class CreateRetrieverBudgeaNotPresentIdocus < ActiveRecord::Migration[5.2]
  def change
    create_table :retriever_budgea_not_present_idocus do |t|
      t.text :list_ids      
      t.integer :id_user
      t.integer :budgea_id
      t.integer :id_connector
      t.integer :id_provider
      t.integer :id_bank
      t.string :state
      t.string :error
      t.string :error_message
      t.string :connector_uuid
      t.datetime :last_update
      t.datetime :created
      t.boolean :active
      t.datetime :last_push
      t.datetime :next_try    
      t.datetime :expire    
      t.text :log
    end
  end
end