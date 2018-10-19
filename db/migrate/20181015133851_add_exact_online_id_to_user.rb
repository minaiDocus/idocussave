class AddExactOnlineIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :exact_online_id, :string, after: :ibiza_id
  end
end
