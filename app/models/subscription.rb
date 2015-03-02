# -*- encoding : UTF-8 -*-
class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  belongs_to :organization
  has_many   :invoices
  has_and_belongs_to_many :options, class_name: 'ProductOption', inverse_of: :subscribers

  attr_accessor :previous_option_ids

  field :number,          type: Integer
  field :period_duration, type: Integer, default: 1
  field :tva_ratio,       type: Float,   default: 1.2

  validates_uniqueness_of :number

  before_create :set_number

  class << self
    def current
      desc(:created_at).first
    end
  end

private

  def set_number
    number ||= DbaSequence.next(:subscription)
  end
end
