# -*- enconding : UTF-8 -*-
class ExpenseCategory < ApplicationRecord
  belongs_to :account_book_type, optional: true

  validates_presence_of :name
end
