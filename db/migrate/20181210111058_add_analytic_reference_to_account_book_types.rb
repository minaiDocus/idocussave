class AddAnalyticReferenceToAccountBookTypes < ActiveRecord::Migration
  def change
    add_column :account_book_types, :analytic_reference_id, :integer
  end
end
