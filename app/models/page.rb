class Page
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :title, :type => String
  field :label, :type => String
  field :meta_description, :type => String
  field :style, :type => String
  field :image, :type => String
  field :image_info, :type => String
  field :is_footer, :type => Boolean, :default => false
  field :position, :type => Integer, :default => 1
  field :is_invisible, :type => Boolean, :default => false
  
  field :content_type, :type => Integer, :default => 1

  slug :label

  embeds_many :page_contents, :dependent => :destroy
  accepts_nested_attributes_for :page_contents, :reject_if => lambda { |a| a[:title].blank? }, :allow_destroy => true

  validates_presence_of :title
  validates_presence_of :label
  validates_presence_of :image
  validates_presence_of :image_info

  class << self
    def in_footer
      where(:is_footer => true)
    end
    
    def not_in_footer
      where(:is_footer => false)
    end

    def by_position
      asc(:position).asc(:title)
    end

    def visible
      where(:is_invisible => false)
    end

    def invisible
      where(:is_invisible => true)
    end
  end

  def self.find_by_type param
    self.all :conditions => {:content_type => param}
  end
  
  def self.find_by_slug param
    self.first :conditions => {:slug => param}
  end
end
