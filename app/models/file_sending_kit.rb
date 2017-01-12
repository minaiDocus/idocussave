# -*- encoding : UTF-8 -*-
class FileSendingKit < ActiveRecord::Base
  validates_presence_of :title, :logo_path, :left_logo_path, :right_logo_path


  belongs_to :organization
end
