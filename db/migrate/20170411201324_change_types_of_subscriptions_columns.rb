class ChangeTypesOfSubscriptionsColumns < ActiveRecord::Migration
  def up
    change_column :subscriptions, :start_date, :date
    change_column :subscriptions, :end_date, :date
  end

  def down
    change_column :subscriptions, :start_date, :datetime
    change_column :subscriptions, :end_date, :datetime
  end
end
