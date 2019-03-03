# -*- encoding : UTF-8 -*-
class PeriodDelivery < ApplicationRecord
  STATES = [%w(rien nothing), %w(attendus wait), %w(réceptionnés received), %w(traités delivered)].freeze

  belongs_to :period, inverse_of: :delivery

  state_machine initial: :wait do
    state :wait
    state :nothing
    state :received
    state :delivered

    event :wait do
      transition [:nothing, :delivered] => :wait
    end

    event :received do
      transition [:nothing, :wait] => :received
    end

    event :delivered do
      transition [:nothing, :wait, :received] => :delivered
    end
  end
end
