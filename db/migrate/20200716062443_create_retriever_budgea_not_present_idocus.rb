class CreateRetrieverBudgeaNotPresentIdocus < ActiveRecord::Migration[5.2]
  def change
    create_table :retriever_budgea_not_present_idocus do |t|
      t.text :list_ids      
      t.integer :id_user
      t.integer :id_connector
      t.string :state
      t.datetime :last_update
      t.datetime :created
      t.boolean :active
      t.datetime :last_push
      t.datetime :next_try         
      t.text :log
    end
  end
end
