class Order::RemindToNewKit
  def self.execute
    total = 0
    Organization.active.each do |organization|
      groups = {}

      organization.customers.active.order(:code).each do |customer|
        next unless customer.subscription.is_package?('mail_option') || customer.subscription.is_package?('ido_annual')

        customer.prescribers.each do |prescriber|
          groups[prescriber] ||= []
          groups[prescriber] << customer.code
        end

        next if customer.notifications.where(notice_type: 'remind_to_order_new_kit').where('created_at > ?', 1.day.ago).present?

        Notifications::Notifier.new.create_notification({
          url: Rails.application.routes.url_helpers.root_url(ActionMailer::Base.default_url_options),
          user: customer,
          notice_type: 'remind_to_order_new_kit',
          title: "Rappel kit courrier",
          message: "Rappel : demande de création d'un nouveau kit courrier auprès de votre cabinet."
        }, false)

        total += 1
      end

      groups.each do |prescriber, customer_codes|
        next if prescriber.notifications.where(notice_type: 'remind_to_order_new_kit').where('created_at > ?', 1.day.ago).present?

        message = "Rappel : n'oubliez pas de créer un nouveau kit courrier pour "
        message += customer_codes.size == 1 ? 'le client suivant : ' : 'les clients suivants : '
        message += customer_codes.join(', ')

        Notifications::Notifier.new.create_notification({
          url: Rails.application.routes.url_helpers.account_organization_customers_url(organization, ActionMailer::Base.default_url_options),
          user: prescriber,
          notice_type: 'remind_to_order_new_kit',
          title: "Rappel kit courrier",
          message: message
        }, false)

        total += 1
      end
    end
    total
  end
end
