class AddCasingCountToPaperSetOrder < ActiveRecord::Migration
  def change
    add_column :orders, :paper_set_casing_count, :integer
  end
end
