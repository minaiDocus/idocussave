class RemoveColumnsFromUsers < ActiveRecord::Migration
  def change
    change_table :users, bulk: true do |t|
      t.remove :rm_is_reminder_email_active, :rm_is_document_notifier_active, :rm_is_mail_receipt_activated
    end
  end
end
