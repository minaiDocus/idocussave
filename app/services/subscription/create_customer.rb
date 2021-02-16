class Subscription::CreateCustomer
  def initialize(organization, requester, params, current_user, request)
    @params       = params
    @request      = request
    @requester    = requester
    @current_user = current_user
    @organization = organization
  end

  def execute
    @customer = User.new @params
    @customer.organization = @organization
    @customer.set_random_password
    @customer.is_group_required = @requester.not_leader?

    if @customer.save
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)

      @customer.reset_password_token   = encrypted_token
      @customer.reset_password_sent_at = Time.now

      Interfaces::Software::Configuration::SOFTWARES.each do |software|
        @customer.send("build_#{software}".to_sym) if @customer.send(software.to_sym).nil? && @customer.organization.send(software.to_sym).present?
      end
      @customer.build_options   if @customer.options.nil?
      @customer.create_notify
      @customer.current_configuration_step = nil

      @customer.save

      AccountingPlan.create(user_id: @customer.id)
      subscription = Subscription.create(user_id: @customer.id)

      scanning_provider = ScanningProvider.default.order(created_at: :asc).first
      if scanning_provider
        scanning_provider.customers << @customer
        scanning_provider.save
      end

      Software::CsvDescriptor.create(owner_id: @customer.id)

      @customer.authd_prev_period            = @organization.authd_prev_period
      @customer.auth_prev_period_until_day   = @organization.auth_prev_period_until_day
      @customer.auth_prev_period_until_month = @organization.auth_prev_period_until_month

      @customer.save

      FileImport::Dropbox.changed(@customer)
      WelcomeMailer.welcome_customer(@customer, token).deliver_later
    end

    @customer
  end
end
