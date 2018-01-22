class CreateFirebaseTokens < ActiveRecord::Migration
  def change
    create_table :firebase_tokens do |t|
      t.belongs_to :user
      t.string :name
      t.string :platform
      t.datetime :last_registration_date
      t.datetime :last_sending_date
      t.datetime :created_at

      t.timestamps null: false
      t.index [:user_id, :name], name: 'index_owener_id_and_name'
    end
  end
end
