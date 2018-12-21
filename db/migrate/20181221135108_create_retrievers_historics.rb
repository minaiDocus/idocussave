class CreateRetrieversHistorics < ActiveRecord::Migration
  def change
    create_table :retrievers_historics do |t|
      t.integer :user_id,       limit: 4
      t.integer :connector_id,  limit: 4
      t.integer :retriever_id,  limit: 4
      t.string  :name
      t.string  :service_name,  limit: 255
      t.integer :banks_count,       default: 0
      t.integer :operations_count,  default: 0
      t.text    :capabilities,  limit: 6553
    end
    add_index :retrievers_historics, :service_name
  end
end