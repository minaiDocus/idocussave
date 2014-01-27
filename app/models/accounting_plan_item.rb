# -*- encoding : UTF-8 -*-
class AccountingPlanItem
  include Mongoid::Document

  embedded_in :accounting_plan_itemable, polymorphic: true

  field :third_party_account
  field :third_party_name
  field :conterpart_account
  field :code

  validates_presence_of :third_party_account
  validates_presence_of :third_party_name
  validates_presence_of :conterpart_account

  default_scope asc: :third_party_name

  def self.find_by_name(name)
    where(third_party_name: name).first
  end

  def self.find_by_code(code)
    where(code: code).first
  end
end