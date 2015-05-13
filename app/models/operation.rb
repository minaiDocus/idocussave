# -*- encoding : UTF-8 -*-
class Operation
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :user
  belongs_to :bank_account
  belongs_to :pack
  belongs_to :piece,   class_name: 'Pack::Piece',              inverse_of: :operations
  has_one :preseizure, class_name: 'Pack::Report::Preseizure', inverse_of: :operation

  index({ fiduceo_id: 1 })

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
  field :processed_at,     type: Time
  field :is_locked,        type: Boolean

  validates_presence_of :date, :label, :amount

  scope :fiduceo,       -> { where(fiduceo_id: { '$exists' => true }) }
  scope :other,         -> { where(fiduceo_id: { '$exists' => false }) }
  scope :not_accessed,  -> { where(accessed_at: nil) }
  scope :not_processed, -> { where(processed_at: { '$exists' => false }) }
  scope :processed,     -> { where(processed_at: { '$ne' => nil }) }
  scope :locked,        -> { where(is_locked: true) }
  scope :not_locked,    -> { where(:is_locked.in => [nil, false]) }
end
