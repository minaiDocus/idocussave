class AddColumn3ToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :new_pre_assignment_available, :boolean, default: true, after: :paper_quota_reached
  end
end
