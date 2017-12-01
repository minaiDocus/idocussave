class UpdateNotifies < ActiveRecord::Migration
  def change
    remove_column :notifies, :published_docs_rm, :boolean

    User.find_each do |user|
      next if user.notify
      user.create_notify(
        to_send_docs:              user.rm_is_reminder_email_active,
        published_docs:            (user.rm_is_document_notifier_active ? 'now' : 'none'),
        reception_of_emailed_docs: user.rm_is_mail_receipt_activated
      )
    end
  end
end
