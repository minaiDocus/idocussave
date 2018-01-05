class CreateAnalyticReferences < ActiveRecord::Migration
  def change
    create_table :analytic_references do |t|
      t.string :name
      t.string :axis1
      t.string :axis2
      t.string :axis3
    end

    add_reference :temp_documents, :analytic_reference, index: true
    add_reference :pack_pieces, :analytic_reference, index: true
  end
end
