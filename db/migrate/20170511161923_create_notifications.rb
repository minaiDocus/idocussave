class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :user, index: true, foreign_key: true
      t.references :targetable, index: true, polymorphic: true
      t.string :notice_type, null: false
      t.boolean :is_read, default: false, null: false
      t.boolean :is_sent, default: false, null: false

      t.timestamps null: false
    end
  end
end
