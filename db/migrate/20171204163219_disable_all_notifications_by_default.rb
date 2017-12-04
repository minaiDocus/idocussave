class DisableAllNotificationsByDefault < ActiveRecord::Migration
  def change
    change_column :notifies, :published_docs,               :string,  default: 'delay'
    change_column :notifies, :r_wrong_pass,                 :boolean, default: false
    change_column :notifies, :r_site_unavailable,           :boolean, default: false
    change_column :notifies, :r_action_needed,              :boolean, default: false
    change_column :notifies, :r_bug,                        :boolean, default: false
    change_column :notifies, :r_new_documents,              :string,  default: 'none'
    change_column :notifies, :r_new_operations,             :string,  default: 'none'
    change_column :notifies, :r_no_bank_account_configured, :boolean, default: false
    change_column :notifies, :document_being_processed,     :boolean, default: false
    change_column :notifies, :paper_quota_reached,          :boolean, default: false
    change_column :notifies, :new_pre_assignment_available, :boolean, default: false
  end
end
