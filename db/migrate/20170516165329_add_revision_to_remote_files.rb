class AddRevisionToRemoteFiles < ActiveRecord::Migration
  def change
    add_column :remote_files, :revision, :string
  end
end
