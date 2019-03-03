class SubscriptionStatistic < ApplicationRecord
  serialize :options, Hash
  serialize :consumption, Hash
  serialize :customers, Array

  attr_accessor :new_customers, :closed_customers

  def self.period_options
    pluck(:month).uniq.reverse
  end

end