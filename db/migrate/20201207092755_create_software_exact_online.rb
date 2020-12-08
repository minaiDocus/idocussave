class CreateSoftwareExactOnline < ActiveRecord::Migration[5.2]
  def change
    create_table :software_exact_online do |t|
      t.text :encrypted_client_id
      t.text :encrypted_client_secret
      t.string :user_name
      t.string :full_name
      t.string :email
      t.string :state
      t.text :encrypted_refresh_token
      t.text :encrypted_access_token
      t.datetime :token_expires_at
      t.boolean :is_used
      t.integer :auto_deliver, default: -1
      t.references :owner, polymorphic: true

      t.timestamps
    end
  end
end
