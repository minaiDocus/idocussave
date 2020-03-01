class RemoveColumnsFromRetriever < ActiveRecord::Migration[5.2]
  def change
    remove_column :retrievers, :fiduceo_id, :string
    remove_column :retrievers, :fiduceo_transaction_id, :string
    remove_column :retrievers, :additionnal_fields, :text
    remove_column :retrievers, :budgea_additionnal_fields, :text
    remove_column :retrievers, :fiduceo_state, :string
    remove_column :retrievers, :fiduceo_additionnal_fields, :text
    remove_column :retrievers, :fiduceo_error_message, :string
    remove_column :retrievers, :connector_id, :integer
    remove_column :retrievers, :encrypted_param1, :text
    remove_column :retrievers, :encrypted_param2, :text
    remove_column :retrievers, :encrypted_param3, :text
    remove_column :retrievers, :encrypted_param4, :text
    remove_column :retrievers, :encrypted_param5, :text
    remove_column :retrievers, :encrypted_answers, :text
  end
end
