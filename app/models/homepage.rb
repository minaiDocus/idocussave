# -*- encoding : UTF-8 -*-
# TODO remove me after migration
class Homepage
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name
  field :style
  field :content, :type => String
  field :meta_description, :type => String
  
  validates_presence_of :content
end
