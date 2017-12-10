class AddIsDuplicateBlockerActivatedForOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :is_duplicate_blocker_activated, :boolean, default: true

    Organization.reset_column_information
    Organization.update_all(is_duplicate_blocker_activated: false)
  end
end
