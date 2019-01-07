class AddIndexToReport < ActiveRecord::Migration
  def change
    add_index :pack_reports, :is_delivered_to
  end
end
