class RenameUsernameInRetriever < ActiveRecord::Migration[5.2]
  def change
    rename_column :retrievers, :username, :login
  end
end
