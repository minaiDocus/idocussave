class AddOrganizationReferencesToDebitMandate < ActiveRecord::Migration
  def change
    add_reference :debit_mandates, :organization, index: true, foreign_key: true
  end
end
