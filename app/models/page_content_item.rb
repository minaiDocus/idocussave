# -*- encoding : UTF-8 -*-
class PageContentItem
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :content, :type => String
  field :image, :type => String
  field :image_info, :type => String
  field :model, :type => Integer, :default => 0
  field :position, :type => Integer, :default => 1
  
  embedded_in :page_content, :inverse_of => :page_content_items
  
  validates_presence_of :content
end
