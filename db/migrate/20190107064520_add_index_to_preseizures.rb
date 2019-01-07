class AddIndexToPreseizures < ActiveRecord::Migration
  def change
    add_index :pack_report_preseizures, :is_delivered_to
  end
end
