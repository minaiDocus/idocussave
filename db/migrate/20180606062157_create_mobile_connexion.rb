class CreateMobileConnexion < ActiveRecord::Migration
  def change
    create_table :mobile_connexions do |t|
      t.integer   :user_id
      t.string    :platform
      t.string    :version
      t.integer   :periode
      t.integer   :daily_counter, default: 1
      t.date      :date
    end
    add_index :mobile_connexions, :periode
    add_index :mobile_connexions, :platform
  end
end
