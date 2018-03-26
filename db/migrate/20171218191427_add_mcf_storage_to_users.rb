class AddMcfStorageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mcf_storage, :string
  end
end
