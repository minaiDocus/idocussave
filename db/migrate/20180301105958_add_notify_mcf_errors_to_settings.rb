class AddNotifyMcfErrorsToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :notify_mcf_errors_to, :text
  end
end
