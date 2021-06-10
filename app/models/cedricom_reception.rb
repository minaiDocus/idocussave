class CedricomReception < ApplicationRecord
  has_one_attached :content

  has_many :operations

  validates_uniqueness_of :cedricom_id

  scope :to_download, -> { where(downloaded: false) }

  scope :to_import, -> { where(imported: false, empty: false, downloaded: true) }
end
