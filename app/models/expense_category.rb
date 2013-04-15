# -*- enconding : UTF-8 -*-
class ExpenseCategory
	include Mongoid::Document

	embedded_in :account_book_type

	field :name, type: String
	field :description, type: String

	validates_presence_of :name
end