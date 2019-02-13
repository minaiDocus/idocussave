class FixIndexOfAdvancedPreseizures < ActiveRecord::Migration
  def change
    remove_index :advanced_preseizures, :third_party    #remove fulltext index
    remove_index :advanced_preseizures, :delivery_message

    add_index :advanced_preseizures, :third_party       #add simple text index
  end
end
