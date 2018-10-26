class AddPreAssignmentExportToNotify < ActiveRecord::Migration
  def change
    add_column :notifies, :pre_assignment_export, :boolean, default: true
  end
end
