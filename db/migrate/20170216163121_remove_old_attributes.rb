class RemoveOldAttributes < ActiveRecord::Migration
  def change
    change_table :budgea_accounts, bulk: true do |t|
      t.remove :old_access_token
    end

    change_table :retrievers, bulk: true do |t|
      t.remove :old_param1
      t.remove :old_param2
      t.remove :old_param3
      t.remove :old_param4
      t.remove :old_param5
      t.remove :old_answers
    end

    change_table :new_provider_requests, bulk: true do |t|
      t.remove :old_url
      t.remove :old_login
      t.remove :old_description
      t.remove :old_message
      t.remove :old_email
      t.remove :old_password
      t.remove :old_types
    end
  end
end
