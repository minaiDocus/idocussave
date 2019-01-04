class CreateExactOnline < ActiveRecord::Migration
  def change
    create_table :exact_online do |t|
      t.text      :encrypted_client_id,      limit: 65535
      t.text      :encrypted_client_secret,  limit: 65535
      t.string    :user_name
      t.string    :full_name
      t.string    :email
      t.string    :state
      t.text      :encrypted_refresh_token, limit: 65535
      t.text      :encrypted_access_token,  limit: 65535
      t.datetime  :token_expires_at
      t.integer   :user_id
      t.datetime  :created_at
      t.datetime  :updated_at
    end
  end
end
