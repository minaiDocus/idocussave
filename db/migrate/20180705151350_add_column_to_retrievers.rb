class AddColumnToRetrievers < ActiveRecord::Migration[5.0]
  def change
    add_column :retrievers, :budgea_connector_id, :integer, default: :null, after: :connector_id
  end
end
