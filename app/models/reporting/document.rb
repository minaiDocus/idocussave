# -*- encoding : UTF-8 -*-
class Reporting::Document
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :monthly, :class_name => "Reporting::Monthly", :inverse_of => :documents
  
  field :name, :type => String
  field :pieces, :type => Integer, :default => 0
  field :sheets, :type => Integer, :default => 0
  field :pages, :type => Integer, :default => 0
  field :clip, :type => Integer, :default => 0
  field :oversize, :type => Integer, :default => 0
  field :uploaded_pieces, :type => Integer, :default => 0
  field :uploaded_sheets, :type => Integer, :default => 0
  field :uploaded_pages, :type => Integer, :default => 0
  field :is_shared, :type => Boolean, :default => false
  
  validates_presence_of :name
  
  scope :shared, :where => { :is_shared => true }
  
  validate :uniqueness_of_name
  
  def scanned_pieces
    pieces - uploaded_pieces
  end
  
  def scanned_sheets
    sheets - uploaded_sheets
  end
  
  def scanned_pages
    pages - uploaded_pages
  end
  
private
  def uniqueness_of_name
    document = self.monthly.documents.where(:name => self.name).first
    if document && document != self
      errors.add(:name, "Document already exist.")
    end
  end
end
