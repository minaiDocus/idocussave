class InvoiceSetting < ApplicationRecord
  validates_presence_of   :user_code, :journal_code

  belongs_to :organization, optional: true
  belongs_to :user, optional: true
  belongs_to :invoice, optional: true
end
