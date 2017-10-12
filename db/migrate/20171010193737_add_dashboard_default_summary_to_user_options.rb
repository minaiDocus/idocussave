class AddDashboardDefaultSummaryToUserOptions < ActiveRecord::Migration
  def change
    add_column :user_options, :dashboard_default_summary, :string, default: 'last_scans'
  end
end
