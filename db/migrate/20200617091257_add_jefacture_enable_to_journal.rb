class AddJefactureEnableToJournal < ActiveRecord::Migration[5.2]
  def change
    add_column :account_book_types, :jefacture_enabled, :boolean
  end
end
