# -*- encoding : UTF-8 -*-
class FileSendingKit < ApplicationRecord
  validates_presence_of :title, :logo_path, :left_logo_path, :right_logo_path

  belongs_to :organization

  def real_logo_path
    CmsImage.get_path_of(logo_path)
  end

  def real_left_logo_path
    CmsImage.get_path_of(left_logo_path)
  end

  def real_right_logo_path
    CmsImage.get_path_of(right_logo_path)
  end
end
