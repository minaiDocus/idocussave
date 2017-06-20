class RemoveOldAttributesFromBoxes < ActiveRecord::Migration
  def change
    change_table :boxes, bulk: true do |t|
      t.remove :old_access_token
      t.remove :old_refresh_token
    end
  end
end
