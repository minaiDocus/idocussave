class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :targetable, polymorphic: true

  validates_presence_of :user
  validates_inclusion_of :notice_type, in: :valid_notice_types

  scope :not_read, -> { where(is_read: false) }

  def valid_notice_types
    ['dropbox_invalid_token']
  end
end
