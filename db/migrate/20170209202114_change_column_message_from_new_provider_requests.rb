class ChangeColumnMessageFromNewProviderRequests < ActiveRecord::Migration
  def up
    change_column :new_provider_requests, :encrypted_message, :text
  end

  def down
    change_column :new_provider_requests, :encrypted_message, :string
  end
end
