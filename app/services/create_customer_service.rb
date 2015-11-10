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
    if @customer.save
      @customer.updated_at ||= Time.now
      @customer.created_at ||= @customer.updated_at
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
      @customer.reset_password_token = encrypted_token
      @customer.reset_password_sent_at = Time.now
      @customer.save

      AccountingPlan.create(user_id: @customer.id)

      # Assign default subscription
      subscription = Subscription.create(user_id: @customer.id)
      period_duration = @subscription_params['type'].to_i rescue nil
      if period_duration.in? [1, 3, 12]
        subscription.update_attribute(:period_duration, period_duration)
      end
      options = DefaultSubscriptionOptionsService.new(subscription.period_duration).execute
      UpdateSubscriptionService.new(subscription, { options: options }, @requester, @request).execute
      PeriodBillingService.new(subscription.current_period).fill_past_with_0

      AssignDefaultJournalsService.new(@customer, @requester, @request).execute

      scanning_provider = ScanningProvider.default.asc(:created_at).first
      if scanning_provider
        scanning_provider.customers << @customer
        scanning_provider.save
      end

      CsvDescriptor.create(user_id: @customer.id)

      @customer.authd_prev_period            = @organization.authd_prev_period
      @customer.auth_prev_period_until_day   = @organization.auth_prev_period_until_day
      @customer.auth_prev_period_until_month = @organization.auth_prev_period_until_month
      @customer.save

      DropboxImportFolder.changed(@customer)

      WelcomeMailer.welcome_customer(@customer, token).deliver
    end
    @customer
  end
end
