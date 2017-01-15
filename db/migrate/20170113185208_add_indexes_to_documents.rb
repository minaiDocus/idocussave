class AddIndexesToDocuments < ActiveRecord::Migration
  def change
    add_index :documents, :origin
    add_index :documents, :is_a_cover
    add_index :documents, :dirty
  end
end
