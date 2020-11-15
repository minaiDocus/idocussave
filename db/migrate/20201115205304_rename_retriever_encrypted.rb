class RenameRetrieverEncrypted < ActiveRecord::Migration[5.2]
  def change
    rename_column :retrievers, :login, :encrypted_login
    rename_column :retrievers, :password, :encrypted_password
  end
end
