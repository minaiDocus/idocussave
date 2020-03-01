class AddLastErrorFetchedToFtp < ActiveRecord::Migration[5.2]
  def change
    add_column :ftps, :error_message, :text, limit: 4294967295, after: :is_configured
    add_column :ftps, :error_fetched_at, :datetime, after: :is_configured
  end
end
