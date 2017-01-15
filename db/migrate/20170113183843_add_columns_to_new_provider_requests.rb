class AddColumnsToNewProviderRequests < ActiveRecord::Migration
  def change
    add_column :new_provider_requests, :api_id, :integer
    add_column :new_provider_requests, :email, :string
    add_column :new_provider_requests, :password, :string
    add_column :new_provider_requests, :types, :string
    add_column :new_provider_requests, :is_sent, :boolean, default: false
  end
end
