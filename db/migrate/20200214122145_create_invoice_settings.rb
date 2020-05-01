class CreateInvoiceSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :invoice_settings do |t|
      t.references :organization, index: true
      t.references :user, index: true
      t.string :user_code
      t.string :journal_code

      t.timestamps
    end
  end
end
