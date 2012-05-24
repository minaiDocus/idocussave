class Scan::Document
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :subscription, :class_name => "Scan::Subscription", :inverse_of => :documents
  referenced_in :period, :class_name => "Scan::Period", :inverse_of => :documents
  referenced_in :pack, :inverse_of => :scan_document
  
  field :title, :type => String, :default => ""
  field :pages, :type => Integer, :default => 0
  field :sheets, :type => Integer, :default => 0
  field :pieces, :type => Integer, :default => 0
  field :uploaded_pages, :type => Integer, :default => 0
  field :uploaded_sheets, :type => Integer, :default => 0
  field :uploaded_pieces, :type => Integer, :default => 0
  field :oversized, :type => Integer, :default => 0
  field :paperclips, :type => Integer, :default => 0
  field :is_shared, :type => Boolean, :default => false
  
  validates_presence_of :name
  validate :uniqueness_of_name
  
  scope :created_at_in, lambda { |time_begin,time_end| where(:created_at.in => time_begin.to_i..time_begin.to_i) }
  scope :shared, :where => { :is_shared => true }
  
  after_save :update_period
  
  def self.by_created_at
    order_by(:created_at, :desc)
  end
  
  def update_period
    period.update_information!
  end
  
  def self.find_by_name name
    where(:name => name).first
  end
  
  def find_or_create_by_name name
    document = period.documents.find_by_name name
    if document
      document
    else
      period.documents.create(:name => name)
    end
  end
  
private
  def uniqueness_of_name
    document = self.period.documents.where(:name => name).first
    if document and document != self
      errors.add(:name, "Document with name '#{name}' already exist.")
    end
  end
end
