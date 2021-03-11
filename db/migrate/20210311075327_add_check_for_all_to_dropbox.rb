class AddCheckForAllToDropbox < ActiveRecord::Migration[5.2]
  def change
    add_column :dropbox_basics, :checked_at_for_all, :datetime, default: -> { 'CURRENT_TIMESTAMP' }, after: :checked_at
  end
end
