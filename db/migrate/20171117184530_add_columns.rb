class AddColumns < ActiveRecord::Migration
  def change
    add_column :notifies, :paper_quota_reached, :boolean, default: true, after: :document_being_processed
    add_column :periods, :is_paper_quota_reached_notified, :boolean, default: false
  end
end
