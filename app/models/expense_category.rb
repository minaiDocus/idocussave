# -*- enconding : UTF-8 -*-
class ExpenseCategory < ActiveRecord::Base
  belongs_to :account_book_type

  validates_presence_of :name
end
