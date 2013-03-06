# -*- encoding : UTF-8 -*-
class FileSendingKit
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title,              type: String,  default: 'Title'
  field :instruction,        type: String,  default: ''
  field :position,           type: Integer, default: 0
  
  field :logo_path,          type: String,  default: 'logo/path'
  field :logo_height,        type: Integer, default: 0
  field :logo_width,         type: Integer, default: 0
  
  field :left_logo_path,     type: String,  default: 'left/logo/path'
  field :left_logo_height,   type: Integer, default: 0
  field :left_logo_width,    type: Integer, default: 0
  
  field :right_logo_path,    type: String,  default: 'right/logo/path'
  field :right_logo_height,  type: Integer, default: 0
  field :right_logo_width,   type: Integer, default: 0
  
  validates_presence_of :organization_id, :title, :logo_path, :left_logo_path, :right_logo_path
  
  belongs_to :organization
  
  class << self
    def by_position
      asc(:position)
    end
  end
end
