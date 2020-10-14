class AddColumnToJournal < ActiveRecord::Migration[5.2]
  def change
  	add_column :account_book_types, :use_pseudonym_for_import, :boolean, after: :pseudonym, default: true
  end
end
