class AddColumnToAdvancedPreseizure < ActiveRecord::Migration
  def change
    add_column :advanced_preseizures, :checked_at, :datetime
    add_index  :advanced_preseizures, :checked_at
  end
end
