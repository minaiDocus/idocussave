class NotifyPaperQuotaReached
  def self.execute
    Period.current.paper_quota_reached.paper_quota_reached_not_notified.each do |period|
      new(period).execute
    end
  end

  def initialize(period)
    @period = period
    @user = period.user
    @parent = @user.parent || @user.organization.leader
  end

  def execute
    if @user.notify.paper_quota_reached
      notification = Notification.new
      notification.user        = @user
      notification.notice_type = 'paper_quota_reached'
      notification.title       = 'Quota de feuille atteint'
      notification.message     = "Votre quota de feuille #{@period.type_name} est atteint."
      notification.url         = url
      notification.save
      NotifyWorker.perform_async(notification.id)
    end

    @user.prescribers.each do |prescriber|
      next unless prescriber.notify.paper_quota_reached
      notification = Notification.new
      notification.user        = prescriber
      notification.notice_type = 'paper_quota_reached'
      notification.title       = 'Quota de feuille atteint'
      notification.message     = "Le quota de feuille #{@period.type_name} est atteint pour le client #{@user.code}. Hors forfait de 0,12 cts HT par feuille et pièce comptable."
      notification.url         = url
      notification.save
      NotifyWorker.perform_async(notification.id)
    end

    @period.update(is_paper_quota_reached_notified: true)
  end

private

  def url
    @url ||= Rails.application.routes.url_helpers.account_reporting_url(ActionMailer::Base.default_url_options)
  end
end
