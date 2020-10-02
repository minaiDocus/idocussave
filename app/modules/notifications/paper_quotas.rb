class Notifications::PaperQuotas < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  def notify_paper_quota_reached
    if @arguments[:user] && @arguments[:user].notify.try(:paper_quota_reached)

      create_notification({
        url: url,
        user: @arguments[:user],
        notice_type: 'paper_quota_reached',
        title: 'Quota de feuille atteint',
        message: "Votre quota de feuille #{@arguments[:period].type_name} est atteint."
      }, true)
    end

    collaborators = []
    if @arguments[:user]
      collaborators = @arguments[:user].prescribers
      indication    = "le client #{@arguments[:user].code}"
    elsif @arguments[:organization]
      collaborators = @arguments[:organization].collaborators
      indication    = "les dossiers mensuels"
    end

    collaborators.each do |prescriber|
      next unless prescriber.notify.try(:paper_quota_reached)

      create_notification({
        url: url,
        user: prescriber,
        notice_type: 'paper_quota_reached',
        title: 'Quota de feuille atteint',
        message: "Le quota de feuille #{@arguments[:period].type_name} est atteint pour #{indication}. Hors forfait de 0,12 cts HT par feuille et pièce comptable."
      }, true)
    end

    @arguments[:period].update(is_paper_quota_reached_notified: true)
  end

  private

  def url
    @url ||= Rails.application.routes.url_helpers.account_reporting_url(ActionMailer::Base.default_url_options)
  end
end
