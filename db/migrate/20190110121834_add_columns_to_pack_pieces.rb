class AddColumnsToPackPieces < ActiveRecord::Migration
  def change
    add_column :pack_pieces, :content_text, :text, limit: 4294967295
    add_column :pack_pieces, :tags, :text, limit: 4294967295
  end
end
