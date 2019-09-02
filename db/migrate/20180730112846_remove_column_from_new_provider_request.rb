class RemoveColumnFromNewProviderRequest < ActiveRecord::Migration
  def change
    remove_column :new_provider_requests, :encrypted_password, :string
    remove_column :new_provider_requests, :encrypted_login, :string
  end
end
