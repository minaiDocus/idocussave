class UpdateMyUnisoft < ActiveRecord::Migration[5.2]
  def change
  	remove_column :my_unisofts, :organization_id, :integer
  	remove_column :my_unisofts, :user_id, :integer
  	remove_column :my_unisofts, :customer_auto_deliver, :integer
  	remove_column :my_unisofts, :organization_auto_deliver, :integer
  	remove_column :my_unisofts, :organization_used, :boolean
  	remove_column :my_unisofts, :user_used, :boolean


  	add_column :my_unisofts, :auto_deliver, :integer, default: -1
  	add_column :my_unisofts, :is_used, :boolean, after: :member_id
  	add_column :my_unisofts, :owner_id, :integer, after: :member_id
  	add_column :my_unisofts, :owner_type, :string, after: :member_id


    add_index :my_unisofts, :is_used
    add_index :my_unisofts, :owner_id
  end
end
