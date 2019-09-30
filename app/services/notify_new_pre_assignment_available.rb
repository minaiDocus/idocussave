class NotifyNewPreAssignmentAvailable
  def initialize(pre_assignment, time_delay=1.minute)
    @pre_assignment = pre_assignment
    @time_delay = time_delay
  end

  def execute
    @pre_assignment.user.prescribers.each do |prescriber|
      next unless prescriber.notify.new_pre_assignment_available
      Notifiable.create(notify: prescriber.notify, notifiable: @pre_assignment, label: 'new')
      NotifyNewPreAssignmentAvailableWorker.perform_in(@time_delay, prescriber.id)
    end
    true
  end

  def self.execute(user_id)
    user = User.find user_id

    collab = (user.collaborator?)? Collaborator.new(user) : user

    list = user.notify.notifiable_new_pre_assignments.includes(notifiable: [:report]).to_a

    return if list.empty?

    notification = Notification.new
    notification.user        = user
    notification.notice_type = 'new_pre_assignment_available'
    notification.title       = list.size == 1 ? 'Nouvelle pré-affectation disponible' : 'Nouvelles pré-affectations disponibles'
    notification.url         = Rails.application.routes.url_helpers.account_organization_pre_assignments_url(collab.organization, ActionMailer::Base.default_url_options)

    notification.message = if list.size == 1
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

    notification.save
    NotifyWorker.perform_async(notification.id)

    list.each(&:delete)
  end
end
