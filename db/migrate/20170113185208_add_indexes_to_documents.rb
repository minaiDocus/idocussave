class AddIndexesToDocuments < ActiveRecord::Migration
  def up
    change_table :documents, bulk: true do |t|
      t.index :origin
      t.index :is_a_cover
      t.index :dirty
    end
  end

  def down
    change_table :documents, bulk: true do |t|
      t.remove_index :origin
      t.remove_index :is_a_cover
      t.remove_index :dirty
    end
  end
end
