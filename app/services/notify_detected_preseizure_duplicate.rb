class NotifyDetectedPreseizureDuplicate
  def initialize(preseizure, time_delay=1.minute)
    @preseizure = preseizure
    @time_delay = time_delay
  end

  def execute
    @preseizure.user.prescribers.each do |collaborator|
      next unless collaborator.notify.detected_preseizure_duplication
      Notify.update_counters collaborator.notify.id, detected_preseizure_duplication_count: 1
      NotifyDetectedPreseizureDuplicateWorker.perform_in(@time_delay, collaborator.id)
    end
    true
  end

  def self.execute(user_id)
    user = User.find user_id
    count = user.notify.detected_preseizure_duplication_count

    return if count == 0

    notification = Notification.new
    notification.user        = user
    notification.notice_type = 'detected_preseizure_duplication'
    notification.title       = count == 1 ? 'Pré-affectation bloqué' : 'Pré-affectations bloqués'
    notification.url         = Rails.application.routes.url_helpers.account_organization_pre_assignment_blocked_duplicates_url(user.organization, ActionMailer::Base.default_url_options)
    notification.message = if count == 1
      "1 pré-affectation est susceptible d'être un doublon et a été bloqué."
    else
      "#{count} pré-affectations sont susceptibles d'être des doublons et ont été bloqués."
    end
    notification.save
    NotifyWorker.perform_async(notification.id)

    Notify.update_counters user.notify.id, detected_preseizure_duplication_count: -count
  end
end
