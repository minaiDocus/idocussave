class AddIsAnalysisActivatedToIbizasAndUserOptions < ActiveRecord::Migration
  def change
    add_column :ibizas,       :is_analysis_activated,        :boolean, default: false
    add_column :user_options, :is_compta_analysis_activated, :integer, default: -1
  end
end
