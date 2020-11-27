class CreateMyUnisoft < ActiveRecord::Migration[5.2]
  def change
    create_table :my_unisofts do |t|
      t.string :encrypted_api_token
      t.string :name
      t.string :access_routes
      t.integer :society_id
      t.integer :member_id
      t.integer :organization_id
      t.integer :user_id 
      t.integer :customer_auto_deliver, default: -1
      t.boolean :organization_auto_deliver, default: false
      t.boolean :organization_used, default: false
      t.boolean :user_used, default: false
      t.boolean :auto_update_accounting_plan, default: false      
    end

    add_index :my_unisofts, :user_id
    add_index :my_unisofts, :organization_id
    add_index :my_unisofts, :user_used
    add_index :my_unisofts, :organization_used
    add_index :my_unisofts, :auto_update_accounting_plan
  end
end