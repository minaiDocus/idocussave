# -*- encoding : UTF-8 -*-
class FileSendingKit < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_center_logo' => ''}
  has_one_attached :cloud_center_logo
  has_one_attached :cloud_left_logo
  has_one_attached :cloud_right_logo

  attr_accessor :center_logo, :left_logo, :right_logo

  validates_presence_of :title
  validates_presence_of :logo_path, :left_logo_path, :right_logo_path, if: proc { |f| f.normal_paper_set_order? }

  belongs_to :organization

  before_destroy do |fsk|
    fsk.cloud_center_logo.purge
    fsk.cloud_left_logo.purge
    fsk.cloud_right_logo.purge
  end

  def real_logo_path
    normal_paper_set_order? ? CmsImage.get_path_of(logo_path) : self.cloud_center_logo_object.try(:reload).try(:path).to_s
  end

  def real_left_logo_path
    normal_paper_set_order? ? CmsImage.get_path_of(left_logo_path) : self.cloud_left_logo_object.try(:reload).try(:path).to_s
  end

  def real_right_logo_path
    normal_paper_set_order? ? CmsImage.get_path_of(right_logo_path) : self.cloud_right_logo_object.try(:reload).try(:path).to_s
  end

  #this method is required to avoid custom_active_storage bug when seeking for paperclip equivalent method
  def center_logo
    object = FakeObject.new
  end

  #this method is required to avoid custom_active_storage bug when seeking for paperclip equivalent method
  def left_logo
    object = FakeObject.new
  end

  #this method is required to avoid custom_active_storage bug when seeking for paperclip equivalent method
  def right_logo
    object = FakeObject.new
  end

  def cloud_center_logo_object
    CustomActiveStorageObject.new(self, :cloud_center_logo)
  end

  def cloud_left_logo_object
    CustomActiveStorageObject.new(self, :cloud_left_logo)
  end

  def cloud_right_logo_object
    CustomActiveStorageObject.new(self, :cloud_right_logo)
  end

  def normal_paper_set_order?
    !CustomUtils.is_manual_paper_set_order?(organization)
  end
end
