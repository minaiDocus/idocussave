class AddSkipAccountNumberRuleFinderToUserOptions < ActiveRecord::Migration[5.2]
  def change
    add_column :user_options, :keep_account_validation, :boolean, default: false, after: :skip_accounting_plan_finder
  end
end
