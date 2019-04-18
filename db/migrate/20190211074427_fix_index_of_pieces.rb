class FixIndexOfPieces < ActiveRecord::Migration[5.2]
  def change
    change_column :pack_pieces, :tags, :text, limit: 65535

    remove_index :pack_pieces, :mongo_id
    remove_index :pack_pieces, name: "organization_id_mongo_id"
    remove_index :pack_pieces, name: "pack_id_mongo_id"
    remove_index :pack_pieces, name: "user_id_mongo_id"

    add_index :pack_pieces, :position
  end
end
