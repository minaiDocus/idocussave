class AddIsDeveloperUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_developer, :boolean, after: :is_prescriber, default: false
  end
end