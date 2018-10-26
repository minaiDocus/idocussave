class CreatePackReportPreseizuresPreAssignmentExport < ActiveRecord::Migration
  def change
    create_table :pack_report_preseizures_pre_assignment_exports do |t|
      t.integer :preseizure_id,            limit: 4
      t.integer :pre_assignment_export_id, limit: 4
    end
  end
end
