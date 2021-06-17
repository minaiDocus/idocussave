class Notifications::PreAssignments < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  def notify_detected_preseizure_duplication
    @arguments[:preseizure].user.prescribers.each do |collaborator|
      next unless collaborator.notify.try(:detected_preseizure_duplication)
      Notify.update_counters collaborator.notify.id, detected_preseizure_duplication_count: 1

      collaborator.notify.reload

      count = collaborator.notify.try(:detected_preseizure_duplication_count)

      return if count == 0

      organization = collaborator.organization
      if collaborator.collaborator?
        collaborator = Collaborator.new collaborator
        organization = collaborator.organizations.first
      end

      create_notification({
        url: Rails.application.routes.url_helpers.account_pre_assignment_blocked_duplicates_path,
        user: collaborator.user,
        notice_type: 'detected_preseizure_duplication',
        title: count == 1 ? 'Pré-affectation bloqué' : 'Pré-affectations bloqués',
        message: count == 1 ? "1 pré-affectation est susceptible d'être un doublon et a été bloqué." : "#{count} pré-affectations sont susceptibles d'être des doublons et ont été bloqués."
      }, true)

      Notify.update_counters collaborator.notify.id, detected_preseizure_duplication_count: -count
    end

    true
  end


  def notify_new_pre_assignment_available
    @arguments[:pre_assignment].user.prescribers.each do |prescriber|
      next unless prescriber.notify.try(:new_pre_assignment_available)
      Notifiable.create(notify: prescriber.notify, notifiable: @arguments[:pre_assignment], label: 'new')

      list = prescriber.notify.notifiable_new_pre_assignments.includes(notifiable: [:report]).to_a

      return if list.empty? || !list.first.try(:notifiable).try(:report).try(:name)

      notification_message = if list.size == 1
        "1 nouvelle pré-affectation est disponible pour le lot suivant : #{list.first.notifiable.report.name}"
      else
        groups = list.map(&:notifiable).group_by(&:report)
        message = "#{list.size} nouvelles pré-affectations sont disponibles pour "
        message += groups.size == 1 ? 'le lot suivant :' : 'les lots suivants :'
        message += "\n\n"
        message += groups.sort_by do |report, preseizures|
          report.name
        end.map do |report, preseizures|
          "* #{report.name} - #{preseizures.size}"
        end.join("\n")
        message
      end

      create_notification({
        url: Rails.application.routes.url_helpers.account_documents_path,
        user: prescriber,
        notice_type: 'new_pre_assignment_available',
        title: list.size == 1 ? 'Nouvelle pré-affectation disponible' : 'Nouvelles pré-affectations disponibles',
        message: notification_message
      }, true)

      list.each(&:delete)
    end
    true
  end

  def notify_pre_assignment_export
    pre_assignment_exports = PreAssignmentExport.not_notified

    return unless pre_assignment_exports.size > 0

    pre_assignment_exports.group_by(&:user_id).each do |pre_assignment_export|
      customer = User.find pre_assignment_export.first
      pre_assignment_export_count = pre_assignment_export.last.size

      collaborators = customer.prescribers
      if collaborators.any?
        collaborators.each do |collaborator|
          message = if pre_assignment_export_count == 1
            "- 1 export d'écritures comptables est disponible pour le dossier : #{customer.code} \n"
          else
            "- #{pre_assignment_export_count} exports d'écritures comptables sont disponibles pour le dossier : #{customer.code} \n"
          end

          create_notification({
            url: Rails.application.routes.url_helpers.account_documents_url(ActionMailer::Base.default_url_options),
            user: collaborator,
            notice_type: 'pre_assignment_export',
            title: "Export d'écritures comptables disponibles",
            message: message
          }, true)
        end
      end
    end

    pre_assignment_exports.update_all({is_notified: true, notified_at: Time.now})
  end

  def notify_pre_assignment_ignored_piece
    @arguments[:piece].user.prescribers.each do |collaborator|
      next unless collaborator.notify.try(:pre_assignment_ignored_piece)
      Notify.update_counters collaborator.notify.id, pre_assignment_ignored_piece_count: 1

      collaborator.notify.reload

      count = collaborator.notify.try(:pre_assignment_ignored_piece_count)

      return if count == 0

      create_notification({
        url: Rails.application.routes.url_helpers.account_pre_assignment_ignored_path,
        user: collaborator,
        notice_type: 'pre_assignment_ignored_piece',
        title: count == 1 ? 'Pièce ignorée à la pré-affectation' : 'Pièces ignorées à la pré-affectation',
        message: count == 1 ? "1 pièce a été ignorée à la pré-affectation" : "#{count} pièces ont été ignorées à la pré-affectation"
      }, true)

      Notify.update_counters collaborator.notify.id, pre_assignment_ignored_piece_count: -count
    end
    true
  end

  def notify_unblocked_preseizure
    @arguments[:owner].prescribers.each do |collaborator|
      next if collaborator == @arguments[:unblocker]
      next unless collaborator.notify.try(:detected_preseizure_duplication)
      Notify.update_counters collaborator.notify.id, unblocked_preseizure_count: @arguments[:total]

      collaborator.notify.reload

      count = collaborator.notify.try(:unblocked_preseizure_count)

      return if count == 0

      if collaborator.notify.try(:detected_preseizure_duplication)
        create_notification({
          url: Rails.application.routes.url_helpers.account_pre_assignment_blocked_duplicates_path,
          user: collaborator,
          notice_type: 'unblocked_preseizure',
          title: count == 1 ? 'Pré-affectation débloqué' : 'Pré-affectations débloqués',
          message: count == 1 ? "1 pré-affectation a été débloqué." : "#{count} pré-affectations ont été débloqués."
        }, true)
      end

      Notify.update_counters collaborator.notify.id, unblocked_preseizure_count: -count
    end
    true
  end

  def notify_pre_assignment_delivery_failure
    users = @arguments[:user].manager ? [@arguments[:user].manager.user] : @arguments[:user].organization.admins

    users.each do |user|
      next unless user.notify.try(:pre_assignment_delivery_errors?)
      Notifiable.create(notify: user.notify, notifiable: @arguments[:delivery], label: 'failure')
      next unless user.notify.try(:pre_assignment_delivery_errors_now?)
      pre_assignment_delivery_for(user)
    end

    true
  end

  def notify_pre_assignment_delivery_failure_daily
    Notifiable.select(:notify_id).distinct.pluck(:notify_id).each do |notify_id|
      notify = Notify.find notify_id
      pre_assignment_delivery_for(notify.user)
    end
  end

  private

  def pre_assignment_delivery_for(user)
    list = user.notify.notifiable_pre_assignment_delivery_failures.includes(:notifiable).to_a

    return if list.empty?

    list.map(&:notifiable).group_by(&:organization).each do |organization, deliveries|
      groups = deliveries.group_by(&:pack_name)
      if groups.size == 1
        message = "La pré-affectation suivante n'a pas pu être livrée : #{groups.first.first}"
      else
        message = "#{groups.size} pré-affectations n'ont pas pu être livrées :\n\n"
        message += groups.sort_by do |pack_name, _|
          pack_name
        end.map do |pack_name, deliveries|
          "* #{pack_name}"
        end.join("\n")
      end

      create_notification({
        url:         Rails.application.routes.url_helpers.account_pre_assignment_delivery_errors_path,
        user:        user,
        notice_type: 'pre_assignment_delivery_failure',
        title:       deliveries.size == 1 ? 'Livraison de pré-affectation échouée' : 'Livraisons de pré-affectation échouées',
        message:     message
      }, false)
    end

    list.each(&:delete)
  end
end