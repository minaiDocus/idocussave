class AddIndexesToRemoteFiles < ActiveRecord::Migration
  def change
    change_table :remote_files, bulk: true do |t|
      t.index :state
      t.index :service_name
      t.index :tried_count
      t.index :extension
    end
  end
end
