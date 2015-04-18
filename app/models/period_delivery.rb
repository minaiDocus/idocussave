# -*- encoding : UTF-8 -*-
class PeriodDelivery
  include Mongoid::Document
  include Mongoid::Timestamps

  # FIXME do that with the builtin i18n rails module
  STATES = [['rien', 'nothing'], ['attendus', 'wait'], ['réceptionnés', 'received'], ['traités', 'delivered']]

  embedded_in :period, inverse_of: :delivery

  field :state, default: 'wait'

  state_machine :initial => :wait do
    state :nothing
    state :wait
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
