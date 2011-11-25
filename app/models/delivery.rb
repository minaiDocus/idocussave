class Delivery
  # FIXME do that with the builtin i18n rails module
  STATES = [['rien', 'nothing'], ['attendus', 'wait'], ['réclamés', 'revival'], ['réceptionnés', 'received'], ['traités', 'delivered'], ['retournés', 'returned']]

  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveRecord::Transitions
  
  referenced_in :user
  
  field :state, :default => 'nothing'
  
  state_machine do
    state :nothing
    state :wait
    state :revival
    state :received
    state :delivered
    state :returned

    event :wait do
      transitions :to => :wait, :from => [:nothing, :returned]
    end
    
    event :revive do
      transitions :to => :revival, :from => [:nothing, :wait]
    end
    
    event :received do
      transitions :to => :received, :from => [:nothing, :wait, :revival]
    end
    
    event :delivered do
      transitions :to => :delivered, :from => [:nothing, :wait, :revival, :received]
    end
    
    event :return do
      transitions :to => :returned, :from => [:nothing, :wait, :revival, :received, :delivered]
    end
    
  end
  
end
