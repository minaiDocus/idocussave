class ChangeRetrieversColumns < ActiveRecord::Migration
  def change
    change_table :retrievers, bulk: true do |t|
      t.rename :param1,  :old_param1
      t.rename :param2,  :old_param2
      t.rename :param3,  :old_param3
      t.rename :param4,  :old_param4
      t.rename :param5,  :old_param5
      t.rename :answers, :old_answers

      t.column :encrypted_param1,  :text
      t.column :encrypted_param2,  :text
      t.column :encrypted_param3,  :text
      t.column :encrypted_param4,  :text
      t.column :encrypted_param5,  :text
      t.column :encrypted_answers, :text
    end
  end
end
