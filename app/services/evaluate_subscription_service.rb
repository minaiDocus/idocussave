class EvaluateSubscriptionService
  ACTIONS = [
    :authorize_dematbox,
    :unauthorize_dematbox,
    :authorize_fiduceo,
    :unauthorize_fiduceo,
    :authorize_preassignment,
    :unauthorize_preassignment,
    :update_max_number_of_journals
  ]

  def self.execute(subscription, collaborator, prev_options=[])
    self.new(subscription, collaborator, prev_options).execute
  end

  def initialize(subscription, collaborator, prev_options=[])
    @subscription           = subscription
    @collaborator           = collaborator
    @user                   = @subscription.user
    @prev_options           = prev_options
  end

  def execute
    options_to_notify = []
    @subscription.product_option_orders.each do |product_option|
      if product_option.notify && !@prev_options.include?(product_option)
        options_to_notify << "#{product_option.group_title} : #{product_option.title}"
      end
      case product_option.action_name
      when 'authorize_dematbox'
        authorize_dematbox
      when 'unauthorize_dematbox'
        unauthorize_dematbox
      when 'authorize_fiduceo'
        authorize_fiduceo
      when 'unauthorize_fiduceo'
        unauthorize_fiduceo
      when 'authorize_preassignment'
        authorize_preassignment
      when 'unauthorize_preassignment'
        unauthorize_preassignment
      when 'update_max_number_of_journals'
        update_max_number_of_journals(product_option)
      end
    end
    notify(options_to_notify) if options_to_notify.present?
  end

private

  def notify(options_to_notify)
    if addresses.size > 0
      NotificationMailer.
        delay(priority: 1).
        subscription_updated(addresses, @collaborator, @user, options_to_notify)
    end
  end

  def addresses
    Array(Settings.notify_subscription_changes_to)
  end

  def authorize_dematbox
    @user.update_attribute(:is_dematbox_authorized, true)
  end

  def unauthorize_dematbox
    @user.update_attribute(:is_dematbox_authorized, false)
  end

  def authorize_fiduceo
    @user.update_attribute(:is_fiduceo_authorized, true)
  end

  def unauthorize_fiduceo
    @user.update_attribute(:is_fiduceo_authorized, false)
  end

  def authorize_preassignment
    @user.options.update_attribute(:is_preassignment_authorized, true)
  end

  def unauthorize_preassignment
    @user.options.update_attribute(:is_preassignment_authorized, false)
  end

  def update_max_number_of_journals(product_option)
    @user.options.update_attribute(:max_number_of_journals, product_option.quantity)
  end
end
