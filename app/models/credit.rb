# -*- encoding : UTF-8 -*-
class Credit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveRecord::Transitions

  after_create :set_number

  field :amount,       type: Integer
  field :number,       type: String
  field :payment_type, type: String
  field :params
  field :state,        default: 'unpaid'

  validates_presence_of :number
  validates_uniqueness_of :number

  index :number, unique: true

  belongs_to :user

  state_machine do
    state :unpaid
    state :paid
    state :canceled
    state :credited

    event :pay do
      transitions to: :paid,     from: %w(unpaid canceled)
    end

    event :cancel do
      transitions to: :canceled, from: %w(unpaid)
    end

    event :credit do
      transitions to: :credited, from: %w(paid)
    end

  end

  def self.find_number(param)
    self.first conditions: { number: param }
  end

  def set_number
    self.number = "CREDIT#{DbaSequence.next(:credit)}"
    self.save!
  end

  def set_pay
    if self.pay!
      self.user.update_attribute(:balance_in_cents,self.user.balance_in_cents + self.amount)
      self.credit!
    end
  end
end
