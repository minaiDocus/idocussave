class CreateArchiveInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :archive_invoices do |t|
      t.string :name

      t.timestamps
    end
  end
end
