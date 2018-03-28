class NotifyNewScannedDocuments
  def initialize(user, new_count)
    @user = user
    @new_count = new_count
  end

  def execute
    period = @user.periods.order(start_date: :desc).first
    total = period.scanned_sheets + @new_count

    users = [@user]
    users += @user.manager ? [@user.manager.user] : @user.organization.admins

    users.compact.each do |user|
      return unless user.notify.new_scanned_documents

      notification = Notification.new
      notification.user        = user
      notification.notice_type = 'new_scanned_documents'
      notification.title       = 'Nouveau document papier reçu'
      if user == @user
        period_name = Period.period_name(period.duration, 0, period.start_date.to_time)
        notification.message   = "Le total des documents papier envoyés pour la période #{period_name} est de : #{total}."
      else
        notification.message   = "Le total des documents papier envoyés par #{@user.info} cette période est : #{total}."
      end
      notification.url         = Rails.application.routes.url_helpers.account_paper_processes_url(ActionMailer::Base.default_url_options)
      notification.save
    end
  end
end
