# -*- encoding : UTF-8 -*-
class AccountingPlanItem < ActiveRecord::Base
  attr_accessor :no_third_party_account

  validates_presence_of :third_party_name
  validates_presence_of :third_party_account, unless: Proc.new { |item| item.no_third_party_account }

  default_scope -> { order(third_party_name: :asc) }

  def self.find_by_name(name)
    where(third_party_name: name).first
  end
end
