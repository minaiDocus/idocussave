class FixSftpsCol < ActiveRecord::Migration[5.2]
  def change
  	change_column :sftps, :previous_import_paths, :text
  end
end
