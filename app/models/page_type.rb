# -*- encoding : UTF-8 -*-
class PageType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :caption, :type => String
  field :number, :type => Integer
  field :position, :type => Integer
  
  validates_presence_of :title
  validates_presence_of :caption
  validates_presence_of :number
  validates_presence_of :position

  class << self
    def by_position
      asc(:position).asc(:title)
    end
  end
  
end
