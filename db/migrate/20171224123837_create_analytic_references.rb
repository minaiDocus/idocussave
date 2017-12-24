class CreateAnalyticReferences < ActiveRecord::Migration
  def change
    create_table :analytic_references do |t|
      t.belongs_to :temp_document, index: true
      t.belongs_to :pack_piece, index: true

      t.string :analytic_id
      t.string :axis1_section_code
      t.string :axis2_section_code
      t.string :axis3_section_code
    end
  end
end
