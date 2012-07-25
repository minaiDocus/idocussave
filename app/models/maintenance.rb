# -*- encoding : UTF-8 -*-
class Maintenance
  include Mongoid::Document
  include Mongoid::Timestamps

  field :starting_date
  field :endding_date
  field :comment
  field :caption
  field :is_invisible, :default => true
  
  #validates_presence_of :starting_date
  #validates_presence_of :endding_date
  #validates_presence_of :comment
  #validates_presence_of :caption
  
end
