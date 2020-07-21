class DeleteTables < ActiveRecord::Migration[5.2]
  def up
  	drop_table :retriever_budgea_not_present_idocus, if_exists: true
  	drop_table :users_budgea_not_present_idocus, if_exists: true
  end
end
