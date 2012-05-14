class PageContent
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title, :type => String
  field :position, :type => Integer, :default => 1
  
  embedded_in :page, :inverse_of => :page_contents
  embeds_many :page_content_items
  accepts_nested_attributes_for :page_content_items, :reject_if => lambda { |a| a[:content].blank? }, :allow_destroy => true
  
  validates_presence_of :title
end
