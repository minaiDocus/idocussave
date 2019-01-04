# -*- encoding : UTF-8 -*-
class Pack::Report::Preseizure::Entry < ActiveRecord::Base
  DEBIT  = 1
  CREDIT = 2

  self.inheritance_column = :_type_disabled


  belongs_to :account   , class_name: 'Pack::Report::Preseizure::Account', inverse_of: :entries
  belongs_to :preseizure, class_name: 'Pack::Report::Preseizure'         , inverse_of: :entries

  scope :by_position, -> { order(position: :asc) }
  scope :debit,       -> { where(type: DEBIT) }
  scope :credit,      -> { where(type: CREDIT) }


  validates_presence_of :type


  def get_debit
    type == DEBIT ? amount : nil
  end


  def get_credit
    type == CREDIT ? amount : nil
  end


  def amount_in_cents
    (amount * 100).round rescue nil
  end


  def self.by_position
    order(type: :asc, number: :asc)
  end
end
