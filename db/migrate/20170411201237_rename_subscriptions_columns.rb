class RenameSubscriptionsColumns < ActiveRecord::Migration
  def change
    change_table :subscriptions, bulk: true do |t|
      t.rename :start_at, :start_date
      t.rename :end_at, :end_date
    end
  end
end
