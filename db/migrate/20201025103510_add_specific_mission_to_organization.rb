class AddSpecificMissionToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :specific_mission, :boolean

    add_index :organizations, :specific_mission
  end
end
