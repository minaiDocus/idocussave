# -*- encoding : UTF-8 -*-
class Operation
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  belongs_to :bank_account

  field :fiduceo_id
  field :date,             type: Date
  field :value_date,       type: Date
  field :transaction_date, type: Date
  field :label
  field :amount,           type: Float
  field :comment
  field :supplier_found
  field :type_id
  field :category_id,      type: Integer
  field :category
  field :accessed_at,      type: Time

  validates_presence_of :date, :label, :amount

  scope :not_accessed, where: { accessed_at: nil }
end
