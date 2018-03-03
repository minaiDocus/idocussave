class AddIsAutoMembershipActivatedToOrganizationGroups < ActiveRecord::Migration
  def change
    add_column :organization_groups, :is_auto_membership_activated, :boolean, after: :description, null: false, default: false
  end
end
