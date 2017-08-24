class AddUrlsToConnectors < ActiveRecord::Migration
  def change
    add_column :connectors, :urls, :text
  end
end
