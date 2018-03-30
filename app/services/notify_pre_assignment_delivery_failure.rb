class NotifyPreAssignmentDeliveryFailure
  def initialize(delivery)
    @delivery = delivery
    @user = @delivery.user
  end

  def execute
    users = @user.manager ? [@user.manager.user] : @user.organization.admins

    users.each do |user|
      next unless user.notify.pre_assignment_delivery_errors?
      Notifiable.create(notify: user.notify, notifiable: @delivery, label: 'failure')
      next unless user.notify.pre_assignment_delivery_errors_now?
      NotifyPreAssignmentDeliveryFailureWorker.perform_in(1.minute, user.id)
    end

    true
  end

  class << self
    def daily
      Notifiable.select(:notify_id).distinct.pluck(:notify_id).each do |notify_id|
        notify = Notify.find notify_id
        execute(notify.user_id)
      end
    end

    def execute(user_id)
      user = User.find user_id

      list = user.notify.notifiable_pre_assignment_delivery_failures.includes(:notifiable).to_a

      return if list.empty?

      list.map(&:notifiable).group_by(&:organization).each do |organization, deliveries|
        notification = Notification.new
        notification.user        = user
        notification.notice_type = 'pre_assignment_delivery_failure'
        notification.title       = deliveries.size == 1 ? 'Livraison de pré-affectation échouée' : 'Livraisons de pré-affectation échouées'
        notification.url         = Rails.application.routes.url_helpers.account_organization_pre_assignment_delivery_errors_url organization, ActionMailer::Base.default_url_options

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
        notification.message = message

        notification.save
      end

      list.each(&:delete)
    end
  end
end
