class AddExactIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :exact_id, :string, after: :ibiza_id
  end
end
