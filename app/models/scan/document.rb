# -*- encoding : UTF-8 -*-
class Scan::Document
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :subscription, class_name: "Scan::Subscription", inverse_of: :documents
  referenced_in :period, class_name: "Scan::Period", inverse_of: :documents
  referenced_in :pack, inverse_of: :scan_documents
  
  field :name,            type: String,  default: ''
  field :pieces,          type: Integer, default: 0
  field :sheets,          type: Integer, default: 0
  field :pages,           type: Integer, default: 0
  field :uploaded_pieces, type: Integer, default: 0
  field :uploaded_sheets, type: Integer, default: 0
  field :uploaded_pages,  type: Integer, default: 0
  field :paperclips,      type: Integer, default: 0
  field :oversized,       type: Integer, default: 0
  field :is_shared,       type: Boolean, default: true
  
  validates_presence_of :name
  validate :uniqueness_of_name
  
  scope :for_time, lambda { |start_time,end_time| where(:created_at.gte => start_time, :created_at.lte => end_time) }
  scope :shared, where: { is_shared: true }
  
  after_save :update_period
  
  def self.by_created_at
    desc(:created_at)
  end
  
  def update_period
    self.period.reload.save
  end
  
  def scanned_pieces
    pieces - uploaded_pieces
  end
  
  def scanned_sheets
    sheets - uploaded_sheets
  end
  
  def scanned_pages
    pages - uploaded_pages
  end
  
  def self.find_by_name(name)
    where(name: name).first
  end
  
  def self.find_or_create_by_name(name, period)
    document = period.documents.find_by_name name
    if document
      document
    else
      document = Scan::Document.new
      document.name = name
      document.period = period
      document.save
      document
    end
  end
  
private

  def uniqueness_of_name
    document = self.period.documents.where(name: name).first
    if document and document != self
      errors.add(:name, "Document with name '#{name}' already exist.")
    end
  end
end
