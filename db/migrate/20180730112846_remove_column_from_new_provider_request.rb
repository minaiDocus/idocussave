class RemoveColumnFromNewProviderRequest < ActiveRecord::Migration
  def change
    remove_column :new_provider_requests, :encrypted_password, :string
  end
end
