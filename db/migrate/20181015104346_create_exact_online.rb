class CreateExactOnline < ActiveRecord::Migration
  def change
    create_table :exact_online do |t|
      t.string    :user_name
      t.string    :full_name
      t.string    :email
      t.string    :state
      t.boolean   :is_auto_deliver
      t.text      :encrypted_refresh_token, limit: 65535
      t.text      :encrypted_access_token,  limit: 65535
      t.integer   :organization_id
      t.datetime  :token_expires_at
      t.datetime  :created_at
      t.datetime  :updated_at
    end
  end
end
