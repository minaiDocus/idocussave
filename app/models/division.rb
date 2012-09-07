# -*- encoding : UTF-8 -*-
class Division
  include Mongoid::Document
  include Mongoid::Timestamps
  
  SHEETS_LEVEL = 0
  PIECES_LEVEL = 1
  
  embedded_in :pack
  
  field :name,         type: String,  default: ""
  field :level,        type: Integer, default: 0
  field :start,        type: Integer, default: 0
  field :end,          type: Integer, default: 0
  field :is_an_upload, type: Boolean, default: false
  field :position,     type: Integer, default: 0
  
  scope :uploaded,      where: { is_an_upload: true }
  scope :scanned,       where: { is_an_upload: false }
  scope :sheets,        where: { level: SHEETS_LEVEL }
  scope :pieces,        where: { level: PIECES_LEVEL }
  scope :of_month,      lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  validates_presence_of :name, :start, :end

  def self.last
    desc(:position).first
  end
  
  def self.pages_count
    self.inject(0) { |result, element| result + element.pages_count }
  end
  
  def pages_count
    self.start - self.end + 1
  end

  def to_file
    path = pack.original_document.content.path
    filename = self.name + '.pdf'
    filepath = File.join('/tmp',filename)
    `pdftk A=#{path} cat A#{self.start}-#{self.end} output #{filepath}`
    open(filepath)
  end
end
