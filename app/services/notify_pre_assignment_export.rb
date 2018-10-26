class NotifyPreAssignmentExport
  class << self
    def execute
      exports_to_notify = PreAssignmentExport.not_notified

      return unless exports_to_notify.size > 0

      notifications = prepare_notifications(exports_to_notify)
      send_notifications(notifications)

      exports_to_notify.update_all({is_notified: true, notified_at: Time.now})
    end

    private

    def prepare_notifications(exports)
      notif_by_collaborators = {}

      exports.group_by(&:user_id).each do |exp|
        customer = User.find exp.first
        exports_count = exp.last.size

        collaborators = customer.prescribers
        if collaborators.any?
          collaborators.each do |collab|
            _id = collab.id.to_s
            notif_by_collaborators[_id] = '' if notif_by_collaborators[_id].nil?

            notif_by_collaborators[_id] += if exports_count == 1
              "- 1 export d'écritures comptables est disponible pour le dossier : #{customer.code} \n"
            else
              "- #{exports_count} exports d'écritures comptables sont disponibles pour le dossier : #{customer.code} \n"
            end
          end
        end
      end

      notif_by_collaborators
    end

    def send_notifications(notifications)
      notifications.each do |collab_id, notif|
        user = User.find collab_id.to_i
        user_collab = user.collaborator? ? Collaborator.new(user) : user

        notification = Notification.new
        notification.user        = user
        notification.notice_type = 'pre_assignment_export'
        notification.title       = "Export d'écritures comptables disponibles"
        notification.url         = Rails.application.routes.url_helpers.account_organization_customers_url(user_collab.organization, ActionMailer::Base.default_url_options)
        notification.message     = notif
        notification.save

        NotifyWorker.perform_async(notification.id) if user.try(:notify).try(:pre_assignment_export)
      end
    end
  end
end