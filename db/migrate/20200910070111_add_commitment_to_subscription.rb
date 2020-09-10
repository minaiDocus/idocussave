class AddCommitmentToSubscription < ActiveRecord::Migration[5.2]
  def change
  	add_column :subscriptions, :commitment_counter, :integer, default: 1, after: :end_date
  end
end
