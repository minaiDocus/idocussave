class AddManagerIdToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :manager, index: true
  end
end
