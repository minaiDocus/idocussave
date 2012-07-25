# -*- encoding : UTF-8 -*-
class SharedDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :owner
  field :observer
  field :is_invisible, :type => Boolean, :default => false
  
  references_one :order
  
  validates_presence_of :owner
  validates_presence_of :observer
  
end
