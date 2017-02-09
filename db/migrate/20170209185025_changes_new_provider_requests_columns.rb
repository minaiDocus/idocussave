class ChangesNewProviderRequestsColumns < ActiveRecord::Migration
  def change
    change_table :new_provider_requests, bulk: true do |t|
      t.rename :url,         :old_url
      t.rename :login,       :old_login
      t.rename :description, :old_description
      t.rename :message,     :old_message
      t.rename :email,       :old_email
      t.rename :password,    :old_password
      t.rename :types,       :old_types

      t.column :encrypted_url,         :text
      t.column :encrypted_login,       :string
      t.column :encrypted_description, :text
      t.column :encrypted_message,     :string
      t.column :encrypted_email,       :string
      t.column :encrypted_password,    :string
      t.column :encrypted_types,       :string
    end
  end
end
