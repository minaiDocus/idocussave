# -*- encoding : UTF-8 -*-
class FileSendingKit
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title, :type => String
  field :instruction, :type => String
  field :idocus_instruction, :type => String
  field :position, :type => Integer, :default => 0
  
  field :logo_path, :type => String
  field :logo_height, :type => Integer, :default => 0
  field :logo_width, :type => Integer, :default => 0
  
  field :left_logo_path, :type => String
  field :left_logo_height, :type => Integer, :default => 0
  field :left_logo_width, :type => Integer, :default => 0
  
  field :right_logo_path, :type => String
  field :right_logo_height, :type => Integer, :default => 0
  field :right_logo_width, :type => Integer, :default => 0
  
  validates_presence_of :title, :instruction, :idocus_instruction, :logo_path, :left_logo_path, :right_logo_path
  
  referenced_in :user
  
  class << self
    def by_position
      order_by(:position.asc)
    end
  end
  
end
