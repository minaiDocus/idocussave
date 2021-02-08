class UpdateSubscriptionColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :futur_packages, :text, after: :tva_ratio
    add_column :subscriptions, :current_packages, :text, after: :tva_ratio
  end
end