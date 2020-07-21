class CreateUsersBudgeaNotPresentIdocus < ActiveRecord::Migration[5.2]
  def change
    create_table :users_budgea_not_present_idocus do |t|
      t.date :signin
      t.string :platform
      t.text :access_token
    end
  end
end
