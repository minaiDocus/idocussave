class BillingHistory < ApplicationRecord
  belongs_to :user
  belongs_to :period


  scope :find_with, -> (value) { where(value_period: value) }
  scope :pending,   -> { where(state: 'pending') }
  scope :processed, -> { where(state: 'processed') }


  state_machine initial: :pending do
    state :pending
    state :processed


    event :processed do
      transition [:pending] => :processed
    end
  end


  def self.find_or_create(value, period)
    find_with(value).first || BillingHistory.create(value_period: value, user: period.try(:user), period: period, state: 'pending', amount: 0.0)
  end
end
