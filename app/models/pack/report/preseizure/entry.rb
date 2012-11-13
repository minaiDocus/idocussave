# -*- encoding : UTF-8 -*-
class Pack::Report::Preseizure::Entry
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :preseizure, class_name: 'Pack::Report::Preseizure'       , inverse_of: :entries
  referenced_in :account   , class_name: 'Pack::Report::Preseizure::Account', inverse_of: :entries

  DEBIT  = 1
  CREDIT = 2

  field :type,   type: Integer
  field :number, type: String
  field :amount, type: Float

  validates_presence_of :type

  def get_debit
    type == DEBIT ? amount : nil
  end

  def get_credit
    type == CREDIT ? amount : nil
  end

  def self.by_number
    asc(:type,:number)
  end

  def self.by_position
    asc(:type,:number)
  end
end
