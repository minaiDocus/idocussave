class RemindToOrderNewKit
  def self.execute
    total = 0
    Organization.active.each do |organization|
      groups = {}
      organization.customers.active.order(:code).each do |customer|
        next unless customer.subscription.is_mail_package_active || customer.subscription.is_annual_package_active

        parent = customer.parent || organization.leader
        if parent
          groups[parent] ||= []
          groups[parent] << customer
        end

        next if customer.notifications.where(notice_type: 'remind_to_order_new_kit').where('created_at > ?', 1.day.ago).present?

        notification = Notification.new
        notification.user        = customer
        notification.notice_type = 'remind_to_order_new_kit'
        notification.title       = 'Rappel kit courrier'
        notification.message     = "Rappel : demande de création d'un nouveau kit courrier auprès de votre cabinet."
        notification.url         = Rails.application.routes.url_helpers.root_url ActionMailer::Base.default_url_options
        notification.save
        total += 1
      end

      groups.each do |parent, customers|
        next if parent.notifications.where(notice_type: 'remind_to_order_new_kit').where('created_at > ?', 1.day.ago).present?

        message = "Rappel : n'oubliez pas de créer un nouveau kit courrier pour "
        message += customers.size == 1 ? 'le client suivant : ' : 'les clients suivants : '
        message += customers.map { |c| c.code }.join(', ')

        notification = Notification.new
        notification.user        = parent
        notification.notice_type = 'remind_to_order_new_kit'
        notification.title       = 'Rappel kit courrier'
        notification.message     = message
        notification.url         = Rails.application.routes.url_helpers.account_organization_customers_url(organization, ActionMailer::Base.default_url_options)
        notification.save
        total += 1
      end
    end
    total
  end
end
