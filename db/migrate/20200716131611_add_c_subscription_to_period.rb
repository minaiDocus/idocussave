class AddCSubscriptionToPeriod < ActiveRecord::Migration[5.2]
  def change
  	add_column :periods, :current_packages, :text, after: :duration
  end
end
