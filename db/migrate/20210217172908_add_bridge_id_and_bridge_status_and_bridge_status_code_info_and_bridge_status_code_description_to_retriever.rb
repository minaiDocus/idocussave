class AddBridgeIdAndBridgeStatusAndBridgeStatusCodeInfoAndBridgeStatusCodeDescriptionToRetriever < ActiveRecord::Migration[5.2]
  def change
    add_column :retrievers, :bridge_id, :integer
    add_column :retrievers, :bridge_status, :string
    add_column :retrievers, :bridge_status_code_info, :string
    add_column :retrievers, :bridge_status_code_description, :string
  end
end
