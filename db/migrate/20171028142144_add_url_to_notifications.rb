class AddUrlToNotifications < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      add_column :notifications, :url, :string

      # Fills URL for old notifications

      url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))
      Notification.where(notice_type: %w(share_account account_sharing_destroyed account_sharing_request_approved account_sharing_request_denied account_sharing_request_canceled)).update_all(url: url)

      Notification.where(notice_type: 'account_sharing_request').each do |notification|
        notification.url = Rails.application.routes.url_helpers.account_organization_account_sharings_url(notification.user.organization, ActionMailer::Base.default_url_options)
        notification.save
      end

      Notification.where(notice_type: 'org_ftp_auth_failure').each do |notification|
        notification.url = Rails.application.routes.url_helpers.account_organization_path(notification.user.organization, { tab: 'ftp' }.merge(ActionMailer::Base.default_url_options))
        notification.save
      end

      url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'efs_management', anchor: 'ftp' }.merge(ActionMailer::Base.default_url_options))
      Notification.where(notice_type: 'ftp_auth_failure').update_all(url: url)

      url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'efs_management', anchor: 'dropbox' }.merge(ActionMailer::Base.default_url_options))
      Notification.where(notice_type: %w(dropbox_invalid_access_token dropbox_insufficient_space)).update_all(url: url)
    end
  end
end
