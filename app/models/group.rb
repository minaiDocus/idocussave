class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :title, :type => String
  field :description, :type => String, :default => ""
  field :position, :type => Integer, :default => 1
  
  validates_presence_of :title
  
  slug :title
  
  referenced_in :product
  references_many :product_options
  
  references_many :required_for, :class_name => 'Group', :inverse_of => :require
  referenced_in :require, :class_name => 'Group', :inverse_of => :required_for
  
  references_many :subgroups, :class_name => 'Group', :inverse_of => :supergroup
  referenced_in :supergroup, :class_name => 'Group', :inverse_of => :subgroups
  
  class << self
    def  by_position
      asc(:product_id).asc(:position).asc(:title)
    end
  end
  
  def self.find_by_slug txt
    self.first :conditions => {:slug => txt}
  end
end
