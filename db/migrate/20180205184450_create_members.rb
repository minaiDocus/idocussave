class CreateMembers < ActiveRecord::Migration
  def up
    create_table :members do |t|
      t.belongs_to :organization, null: false
      t.belongs_to :user, null: false

      t.index [:organization_id, :user_id], name: 'index_organization_user_on_members', unique: true

      t.timestamps null: false

      t.column :role, :string, default: 'collaborator', null: false
      t.column :code, :string, null: false

      t.index :role
      t.index :code, unique: true

      t.column :manage_groups,            :boolean, default: true
      t.column :manage_collaborators,     :boolean, default: false
      t.column :manage_customers,         :boolean, default: true
      t.column :manage_journals,          :boolean, default: true
      t.column :manage_customer_journals, :boolean, default: true
    end

    create_table :groups_members do |t|
      t.belongs_to :member, null: false
      t.belongs_to :group, null: false

      t.index [:member_id, :group_id], unique: true
    end

    change_column :groups_users, :user_id, :integer, null: false
    change_column :groups_users, :group_id, :integer, null: false

    add_index :groups_users, [:user_id, :group_id], unique: true
  end

  def down
    drop_table :members
    drop_table :groups_members
    change_column :groups_users, :user_id, :integer, null: true
    change_column :groups_users, :group_id, :integer, null: true
    remove_index :groups_users, [:user_id, :group_id]
  end
end
