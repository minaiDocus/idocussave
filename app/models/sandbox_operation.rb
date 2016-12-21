# -*- encoding : UTF-8 -*-
class SandboxOperation
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :user,                 index: true
  belongs_to :sandbox_bank_account, index: true

  index({ api_id: 1 })
  index({ api_name: 1 })

  field :api_id
  field :api_name, default: 'budgea'

  field :date,             type: Date
  field :value_date,       type: Date
  field :transaction_date, type: Date
  field :label
  field :amount,           type: Float
  field :comment
  field :supplier_found
  field :type
  field :category_id,      type: Integer
  field :category
  field :is_locked,        type: Boolean

  validates_presence_of :date, :label, :amount
end
