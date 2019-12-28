class Notification < ApplicationRecord
  belongs_to :user

  validates_presence_of :user
  validates_inclusion_of :notice_type, in: :notice_types

  scope :not_read, -> { where(is_read: false) }

  class << self
    def search(contains)
      notifications = Notification.all

      if contains[:created_at].present?
        contains[:created_at].each do |operator, value|
          notifications = notifications.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:user_contains] && contains[:user_contains][:code].present?
        user = User.where(code: contains[:user_contains][:code]).first
        notifications = notifications.where(user_id: user.try(:id))
      end

      notifications = notifications.where(notice_type: contains[:notice_type])         if contains[:notice_type].present?
      notifications = notifications.where("title LIKE ?", "%#{contains[:title]}%")     if contains[:title].present?
      notifications = notifications.where("message LIKE ?", "%#{contains[:message]}%") if contains[:message].present?
      notifications = notifications.where(is_sent: (contains[:is_sent] == '1'))        if contains[:is_sent].present?
      notifications = notifications.where(is_read: (contains[:is_read] == '1'))        if contains[:is_read].present?

      notifications
    end

    def notice_types
      [
        'test',
        'dropbox_invalid_access_token',
        'dropbox_insufficient_space',
        'share_account',
        'account_sharing_destroyed',
        'account_sharing_request',
        'account_sharing_request_approved',
        'account_sharing_request_denied',
        'account_sharing_request_canceled',
        'org_ftp_auth_failure',
        'ftp_auth_failure',
        'retriever_wrong_pass',
        'retriever_info_needed',
        'retriever_action_needed',
        'retriever_website_unavailable',
        'retriever_bug',
        'retriever_no_bank_account_configured',
        'retriever_new_documents',
        'retriever_new_operations',
        'invoice',
        'document_being_processed',
        'remind_to_order_new_kit',
        'paper_quota_reached',
        'new_pre_assignment_available',
        'published_document',
        'ibiza_invalid_access_token',
        'detected_preseizure_duplication',
        'unblocked_preseizure',
        'new_scanned_documents',
        'pre_assignment_delivery_failure',
        'mcf_invalid_access_token',
        'mcf_insufficient_space',
        'pre_assignment_ignored_piece',
        'mcf_document_errors',
        'pre_assignment_export',
      ].freeze
    end
  end

  def notice_types
    self.class.notice_types
  end
end
