class CreateCustomerService
  def initialize(organization, requester, params, subscription_params, current_user, request)
    @organization        = organization
    @requester           = requester
    @params              = params
    @subscription_params = subscription_params
    @current_user        = current_user
    @request             = request
  end

  def execute
    @customer = User.new @params
    @customer.organization = @organization
    @customer.set_random_password
    @customer.is_group_required = !(@requester.my_organization || @requester.is_admin)
    @customer.skip_confirmation!
    @customer.reset_password_token = User.reset_password_token
    @customer.reset_password_sent_at = Time.now
    if @customer.save
      AccountingPlan.create(user_id: @customer.id)

      # Assign default subscription
      subscription = @customer.find_or_create_subscription
      case @subscription_params['type']
      when '1'
        subscription.period_duration = 1
      when '3'
        subscription.period_duration = 3
      end
      subscription.save
      options = DefaultSubscriptionOptionsService.new(subscription.period_duration).execute
      UpdateSubscriptionService.new(subscription, { options: options }, @requester)

      # Assign journals
      source = (@organization.is_journals_management_centralized || @requester.is_admin) ? @organization : @requester
      journals = source.account_book_types.default.asc(:name).limit(@customer.options.max_number_of_journals)
      journals = @customer.options.is_preassignment_authorized ? journals : journals.not_compta_processable
      journals.each do |journal|
        unless @customer.account_book_types.count >= @customer.options.max_number_of_journals
          copy = journal.dup
          copy.user         = @customer
          copy.organization = nil
          copy.is_default   = nil
          copy.slug         = nil
          copy.save
          EventCreateService.new.add_journal(copy, @customer, @current_user, path: @request.path, ip_address: @request.remote_ip)
        end
      end

      scanning_provider = ScanningProvider.default.asc(:created_at).first
      if scanning_provider
        scanning_provider.customers << @customer
        scanning_provider.save
      end

      @customer.authd_prev_period            = @organization.authd_prev_period
      @customer.auth_prev_period_until_day   = @organization.auth_prev_period_until_day
      @customer.auth_prev_period_until_month = @organization.auth_prev_period_until_month
      @customer.save

      WelcomeMailer.welcome_customer(@customer).deliver
    end
    @customer
  end
end
