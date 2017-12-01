class CreateNotifies < ActiveRecord::Migration
  def up
    create_table :notifies do |t|
      t.boolean :to_send_docs,                 default: true
      t.boolean :published_docs,               default: true
      t.boolean :reception_of_emailed_docs,    default: true
      t.boolean :r_site_unavailable,           default: true
      t.boolean :r_action_needed,              default: true
      t.boolean :r_bug,                        default: true
      t.string  :r_new_documents,  limit: 5,   default: 'now'
      t.integer :r_new_documents_count,        default: 0
      t.string  :r_new_operations, limit: 5,   default: 'now'
      t.integer :r_new_operations_count,       default: 0
      t.boolean :r_no_bank_account_configured, default: true

      t.timestamps null: false

      t.references :user, index: true

      t.index :r_new_documents_count
      t.index :r_new_operations_count
    end

    rename_column :users, :is_reminder_email_active,    :rm_is_reminder_email_active
    rename_column :users, :is_document_notifier_active, :rm_is_document_notifier_active
    rename_column :users, :is_mail_receipt_activated,   :rm_is_mail_receipt_activated
  end

  def down
    rename_column :users, :rm_is_reminder_email_active,    :is_reminder_email_active
    rename_column :users, :rm_is_document_notifier_active, :is_document_notifier_active
    rename_column :users, :rm_is_mail_receipt_activated,   :is_mail_receipt_activated

    drop_table :notifies
  end
end
