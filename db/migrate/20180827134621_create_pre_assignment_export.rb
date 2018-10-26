class CreatePreAssignmentExport < ActiveRecord::Migration
  def change
    create_table :pre_assignment_exports do |t|
      t.string   :state
      t.string   :pack_name
      t.string   :for
      t.string   :file_name
      t.integer  :total_item,      default: 0
      t.text     :error_message,   limit: 65535
      t.boolean  :is_notified,     default: false
      t.datetime :notified_at
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :user_id
      t.integer  :organization_id
      t.integer  :report_id
    end
    add_index :pre_assignment_exports, :for
    add_index :pre_assignment_exports, :pack_name
    add_index :pre_assignment_exports, :state
  end
end
