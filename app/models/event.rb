class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String, :default => ""
  field :quantity, :type => Integer, :default => 0
  field :amount_in_cents, :type => Integer, :default => 0
  field :type_number, :type => Integer, :default => 0
  
  validates_presence_of :title  
  
  referenced_in :user
  references_one :invoice
  
end
