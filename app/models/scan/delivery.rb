# -*- encoding : UTF-8 -*-
class Scan::Delivery
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveRecord::Transitions

  # FIXME do that with the builtin i18n rails module
  STATES = [['rien', 'nothing'], ['attendus', 'wait'], ['réceptionnés', 'received'], ['traités', 'delivered']]

  embedded_in :period, class_name: "Scan::Period", inverse_of: :delivery

  field :state, default: 'wait'

  state_machine do
    state :nothing
    state :wait
    state :received
    state :delivered

    event :wait do
      transitions to: :wait,      from: [:nothing, :delivered]
    end

    event :received do
      transitions to: :received,  from: [:nothing, :wait]
    end

    event :delivered do
      transitions to: :delivered, from: [:nothing, :wait, :received]
    end

  end
end
