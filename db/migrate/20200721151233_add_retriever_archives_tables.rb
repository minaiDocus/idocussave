class AddRetrieverArchivesTables < ActiveRecord::Migration[5.2]
  def change
  	create_table :archive_retrievers do |t|
      t.integer	:owner_id
      t.integer :budgea_id
      t.integer :id_connector
      t.string 	:state
      t.string 	:error
      t.string 	:error_message
      t.datetime :last_update
      t.datetime :created
      t.boolean  :active
      t.datetime :last_push
      t.datetime :next_try    
      t.datetime :expire    
      t.text 	   :log
      t.boolean  :exist
    end
  end
end
