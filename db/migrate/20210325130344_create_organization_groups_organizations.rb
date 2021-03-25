class CreateOrganizationGroupsOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_groups_organizations do |t|
      t.integer :organization_id
      t.integer :organization_group_id
    end
  end
end
