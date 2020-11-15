class AddUsernameAndPasswordToRetriever < ActiveRecord::Migration[5.2]
  def change
    add_column :retrievers, :username, :string
    add_column :retrievers, :password, :string
  end
end
