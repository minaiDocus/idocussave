class AddIndexesToPackDividers < ActiveRecord::Migration
  def change
    add_index :pack_dividers, :type
    add_index :pack_dividers, :origin
    add_index :pack_dividers, :is_a_cover
  end
end
