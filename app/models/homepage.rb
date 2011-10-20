class Homepage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :style
  field :content, :type => String
  field :meta_description, :type => String
  
  validates_presence_of :content
  
  references_many :slides
  references_many :pavets
  
end
