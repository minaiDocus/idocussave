class AddColumnsToFtps < ActiveRecord::Migration
  def change
    add_column :ftps, :root_path,             :string, default: '/'
    add_column :ftps, :import_checked_at,     :datetime
    add_column :ftps, :previous_import_paths, :text

    add_reference :ftps, :organization, index: true
  end
end
