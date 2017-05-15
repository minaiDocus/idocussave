class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :targetable, polymorphic: true

  validates_presence_of :user
  validates_inclusion_of :notice_type, in: :valid_notice_types

  scope :not_read, -> { where(is_read: false) }

  class << self
    def search(contains)
      notifications = Notification.all

      if contains[:created_at].present?
        contains[:created_at].each do |operator, value|
          notifications = notifications.where("created_at #{operator} '#{value}'")
        end
      end

      if contains[:user_contains] && contains[:user_contains][:code].present?
        user = User.where(code: contains[:user_contains][:code]).first
        notifications = notifications.where(user_id: user.try(:id))
      end

      notifications = notifications.where(notice_type: contains[:notice_type])  if contains[:notice_type].present?
      notifications = notifications.where(is_sent: (contains[:is_sent] == '1')) if contains[:is_sent].present?
      notifications = notifications.where(is_read: (contains[:is_read] == '1')) if contains[:is_read].present?

      notifications
    end
  end

  def valid_notice_types
    ['dropbox_invalid_token']
  end
end
