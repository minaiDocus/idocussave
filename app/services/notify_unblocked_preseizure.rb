class NotifyUnblockedPreseizure
  def initialize(owner, total, unblocker=nil, time_delay=1.minute)
    @owner = owner
    @total = total
    @unblocker = unblocker
    @time_delay = time_delay
  end

  def execute
    @owner.prescribers.each do |collaborator|
      next if collaborator == @unblocker
      next unless collaborator.notify.detected_preseizure_duplication
      Notify.update_counters collaborator.notify.id, unblocked_preseizure_count: @total
      NotifyUnblockedPreseizureWorker.perform_in(@time_delay, collaborator.id)
    end
    true
  end

  def self.execute(user_id)
    user = User.find user_id
    count = user.notify.unblocked_preseizure_count

    return if count == 0

    if user.notify.detected_preseizure_duplication
      notification = Notification.new
      notification.user        = user
      notification.notice_type = 'unblocked_preseizure'
      notification.title       = count == 1 ? 'Pré-affectation débloqué' : 'Pré-affectations débloqués'
      notification.url         = Rails.application.routes.url_helpers.account_pre_assignment_blocked_duplicates_path
      notification.message     = count == 1 ? "1 pré-affectation a été débloqué." : "#{count} pré-affectations ont été débloqués."
      notification.save
      NotifyWorker.perform_async(notification.id)
    end

    Notify.update_counters user.notify.id, unblocked_preseizure_count: -count
  end
end
