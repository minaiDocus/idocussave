class EvaluateSubscriptionService
  ACTIONS = [
    :authorize_dematbox,
    :authorize_fiduceo,
    :authorize_preassignment,
    :update_max_number_of_journals
  ]

  def self.execute(subscription, collaborator, request=nil)
    self.new(subscription, collaborator, request).execute
  end

  def initialize(subscription, collaborator, request=nil)
    @subscription        = subscription
    @collaborator        = collaborator
    @request             = request
    @user                = @subscription.user
    @previous_option_ids = @subscription.previous_option_ids
  end

  def execute
    is_dematbox_authorized      = false
    is_fiduceo_authorized       = false
    is_preassignment_authorized = false

    options_to_notify = []
    @subscription.options.each do |product_option|
      if product_option.notify && !@previous_option_ids.include?(product_option.id)
        options_to_notify << "#{product_option.group_title} : #{product_option.title}"
      end
      Array(product_option.action_names).each do |action_name|
        case action_name
        when 'authorize_dematbox'
          is_dematbox_authorized = true
        when 'authorize_fiduceo'
          is_fiduceo_authorized = true
        when 'authorize_preassignment'
          is_preassignment_authorized = true
        when 'update_max_number_of_journals'
          update_max_number_of_journals(product_option)
        end
      end
    end

    is_dematbox_authorized      ? authorize_dematbox      : unauthorize_dematbox
    is_fiduceo_authorized       ? authorize_fiduceo       : unauthorize_fiduceo
    is_preassignment_authorized ? authorize_preassignment : unauthorize_preassignment
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
    @user.update_attribute(:is_dematbox_authorized, true) unless @user.is_dematbox_authorized
  end

  def unauthorize_dematbox
    @user.update_attribute(:is_dematbox_authorized, false) if @user.is_dematbox_authorized
  end

  def authorize_fiduceo
    @user.update_attribute(:is_fiduceo_authorized, true) unless @user.is_fiduceo_authorized
  end

  def unauthorize_fiduceo
    if @user.is_fiduceo_authorized
      @user.update_attribute(:is_fiduceo_authorized, false)
      RemoveFiduceoService.new(@user.id.to_s).delay.execute if @user.fiduceo_id.present?
    end
  end

  def authorize_preassignment
    unless @user.options.is_preassignment_authorized
      @user.options.update_attribute(:is_preassignment_authorized, true)
      AssignDefaultJournalsService.new(@user, @collaborator, @request).execute
    end
  end

  def unauthorize_preassignment
    if @user.options.is_preassignment_authorized
      @user.options.update_attribute(:is_preassignment_authorized, false)
      @user.account_book_types.pre_assignment_processable.each do |journal|
        journal.reset_compta_attributes
        changes = journal.changes
        if journal.save
          params = [journal, @user, changes, @collaborator]
          params << { path: @request.path, ip_address: @request.remote_ip } if @request
          EventCreateService.new.journal_update(*params)
        end
      end
    end
  end

  def update_max_number_of_journals(product_option)
    unless @user.options.max_number_of_journals == product_option.quantity
      @user.options.update_attribute(:max_number_of_journals, product_option.quantity)
    end
  end
end
