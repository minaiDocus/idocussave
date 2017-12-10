class AddDuplicationColumnsToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :detected_preseizure_duplication, :boolean, default: false, after: :ftp_auth_failure
    add_column :notifies, :detected_preseizure_duplication_count, :integer, default: 0, after: :detected_preseizure_duplication
    add_column :notifies, :unblocked_preseizure_count, :integer, default: 0, after: :detected_preseizure_duplication_count
  end
end
