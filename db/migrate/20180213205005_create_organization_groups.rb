class CreateOrganizationGroups < ActiveRecord::Migration
  def change
    create_table :organization_groups do |t|
      t.column :name, :string, null: false
      t.column :description, :string

      t.timestamps null: false
    end

    change_table :organizations do |t|
      t.belongs_to :organization_group, index: true
    end
  end
end
