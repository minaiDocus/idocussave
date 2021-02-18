class AddActAsCollaboratorToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :act_as_a_collaborator_into_pre_assignment, :boolean, after: :is_pre_assignement_displayed, default: false
  end
end
