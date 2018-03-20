class NotifyNewScannedDocuments
  def initialize(user, new_count)
    @user = user
    @new_count = new_count
  end

  def execute
    total = @user.periods.order(start_date: :desc).first.scanned_sheets + @new_count

    [@user, @user.parent || @user.organization.leader].compact.each do |user|
      return unless user.notify.new_scanned_documents

      notification = Notification.new
      notification.user        = user
      notification.notice_type = 'new_scanned_documents'
      notification.title       = 'Nouveau document papier reçu'
      notification.message     = "Votre total des documents papier envoyés cette période est : #{total}."
      notification.url         = Rails.application.routes.url_helpers.account_paper_processes_url(ActionMailer::Base.default_url_options)
      NotifyWorker.perform_async(notification.id) if notification.save
    end
  end
end
