class BillingHistory < ApplicationRecord
  belongs_to :user
  belongs_to :period

  validate :uniqness_of_value_period

  scope :find_with, -> (value) { where(value_period: value) }
  scope :pending,   -> { where(state: 'pending') }
  scope :processed, -> { where(state: 'processed') }


  state_machine initial: :pending do
    state :pending
    state :processed
    state :unprocessed


    event :unprocessed do
      transition [:pending] => :unprocessed
    end

    event :processed do
      transition [:pending] => :processed
    end
  end


  def self.find_or_create(value, period)
    find_with(value).first || BillingHistory.create(value_period: value, user: period.user, period: period, state: 'pending', amount: 0.0)
  end

  private

  def uniqness_of_value_period
    billing_history = user.billing_histories.where(value_period: value_period).first

    errors.add(:value_period, :taken) if billing_history && billing_history != self
  end
end
