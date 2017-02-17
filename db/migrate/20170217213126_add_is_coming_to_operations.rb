class AddIsComingToOperations < ActiveRecord::Migration
  def change
    add_column :operations, :is_coming, :boolean, default: false
  end
end
