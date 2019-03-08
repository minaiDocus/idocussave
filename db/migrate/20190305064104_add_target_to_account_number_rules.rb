class AddTargetToAccountNumberRules < ActiveRecord::Migration
  def change
    add_column :account_number_rules, :rule_target, :string, default: 'both', after: :rule_type
  end
end
