class AddIsPreAssignementDisplayedToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_pre_assignement_displayed, :boolean, after: :organization_rights_is_collaborators_management_authorized, default: false
  end
end
