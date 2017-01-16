class AddColumnsToRetrievers < ActiveRecord::Migration
  def change
    add_column :retrievers, :fiduceo_service_name, :string
    add_column :retrievers, :fiduceo_capabilities, :text
  end
end
