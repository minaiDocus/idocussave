class ChangeTypesOfPeriodsColumns < ActiveRecord::Migration
  def up
    change_column :periods, :start_date, :date
    change_column :periods, :end_date, :date
  end

  def down
    change_column :periods, :start_date, :datetime
    change_column :periods, :end_date, :datetime
  end
end
