class NotifyPreAssignmentIgnoredPiece
  def initialize(piece, time_delay=1.minute)
    @piece = piece
    @time_delay = time_delay
  end

  def execute
    @piece.user.prescribers.each do |collaborator|
      next unless collaborator.notify.try(:pre_assignment_ignored_piece)
      Notify.update_counters collaborator.notify.id, pre_assignment_ignored_piece_count: 1
      NotifyPreAssignmentIgnoredPieceWorker.perform_in(@time_delay, collaborator.id)
    end
    true
  end

  def self.execute(user_id)
    user = User.find user_id
    user_collab = user.collaborator? ? Collaborator.new(user) : user

    count = user.notify.pre_assignment_ignored_piece_count

    return if count == 0

    notification = Notification.new
    notification.user        = user
    notification.notice_type = 'pre_assignment_ignored_piece'
    notification.title       = count == 1 ? 'Pièce ignorée à la pré-affectation' : 'Pièces ignorées à la pré-affectation'
    notification.url         = Rails.application.routes.url_helpers.account_pre_assignment_ignored_path
    notification.message = if count == 1
      "1 pièce a été ignorée à la pré-affectation"
    else
      "#{count} pièces ont été ignorées à la pré-affectation"
    end
    notification.save
    NotifyWorker.perform_async(notification.id)

    Notify.update_counters user.notify.id, pre_assignment_ignored_piece_count: -count
  end
end
