class AddCasingCountToPaperSetOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :paper_set_casing_count, :integer
  end
end
