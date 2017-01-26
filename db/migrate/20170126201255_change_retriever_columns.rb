class ChangeRetrieverColumns < ActiveRecord::Migration
  def change
    rename_column :retrievers, :fiduceo_capabilities, :capabilities
    rename_column :retrievers, :fiduceo_service_name, :service_name
  end
end
