class AddAnalysisValidationToIbiza < ActiveRecord::Migration
  def change
    add_column :ibizas, :is_analysis_to_validate, :boolean, default: false, after: :is_analysis_activated
  end
end
