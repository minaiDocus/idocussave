class CreateAdvancedPreseizures < ActiveRecord::Migration
  def change
    create_table :advanced_preseizures, options: 'ENGINE=MyISAM DEFAULT CHARSET=utf8' do |t|
      t.integer :user_id,          limit: 4
      t.integer :organization_id,  limit: 4
      t.integer :report_id,        limit: 4
      t.integer :piece_id,         limit: 4
      t.integer :pack_id,          limit: 4
      t.integer :operation_id,     limit: 4
      t.integer :position,         limit: 4
      t.datetime :date
      t.datetime :deadline_date
      t.datetime :delivery_tried_at
      t.text     :delivery_message, limit: 65535
      t.string  :name
      t.string  :piece_number
      t.string  :third_party
      t.decimal :cached_amount,    precision: 11, scale: 2
      t.string  :delivery_state,   limit: 20
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :advanced_preseizures, :name
    add_index :advanced_preseizures, :position
    add_index :advanced_preseizures, :third_party, type: :fulltext
    add_index :advanced_preseizures, :delivery_message, type: :fulltext
    add_index :advanced_preseizures, :delivery_state
    add_index :advanced_preseizures, :updated_at
  end
end