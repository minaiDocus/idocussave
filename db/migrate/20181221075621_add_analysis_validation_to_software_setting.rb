class AddAnalysisValidationToSoftwareSetting < ActiveRecord::Migration
  def change
    add_column :softwares_settings, :is_ibiza_analysis_to_validate, :integer, limit: 4, default: -1, null: false, after: :is_ibiza_compta_analysis_activated
  end
end
