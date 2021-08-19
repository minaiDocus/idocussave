class CedricomReception < ApplicationRecord
  has_one_attached :content

  belongs_to :organization
  has_many :operations

  validates_uniqueness_of :cedricom_id, scope: :organization_id

  scope :to_download, -> { where(downloaded: false) }

  scope :to_import, -> { where(imported: false, empty: false, downloaded: true) }
end
