class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :description, :type => String, :default => ""
  field :quantity, :type => Integer, :default => 1
  field :cost_in_cents, :type => Integer, :default => 0
  
  referenced_in :user
  
end
