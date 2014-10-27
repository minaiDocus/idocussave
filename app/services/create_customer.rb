class CreateCustomer
  attr_reader :customer

  def initialize(organization, requester, params, current_user, request)
    @customer = User.new params
    @customer.organization = organization
    @customer.set_random_password
    @customer.is_group_required = !(requester.my_organization || requester.is_admin)
    @customer.skip_confirmation!
    if @customer.save
      AccountingPlan.create(user_id: @customer.id)

      # Assign default subscription
      subscription = @customer.find_or_create_scan_subscription
      requester_subscription = requester.find_or_create_scan_subscription
      subscription.extend NewSubscription
      subscription.copy requester_subscription
      EvaluateSubscriptionService.execute(subscription, requester)

      # Assign journals
      source = (organization.is_journals_management_centralized || requester.is_admin) ? organization : requester
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
          EventCreateService.new.add_journal(copy, @customer, current_user, path: request.path, ip_address: request.remote_ip)
        end
      end

      scanning_provider = ScanningProvider.default.asc(:created_at).first
      if scanning_provider
        scanning_provider.customers << @customer
        scanning_provider.save
      end

      @customer.authd_prev_period            = organization.authd_prev_period
      @customer.auth_prev_period_until_day   = organization.auth_prev_period_until_day
      @customer.auth_prev_period_until_month = organization.auth_prev_period_until_month
      @customer.save
    end
  end

  module NewSubscription
    def copy(subscription)
      self.period_duration = subscription.period_duration
      self.max_sheets_authorized = subscription.max_sheets_authorized
      self.max_upload_pages_authorized = subscription.max_upload_pages_authorized
      self.quantity_of_a_lot_of_upload = subscription.quantity_of_a_lot_of_upload
      self.max_preseizure_pieces_authorized = subscription.max_preseizure_pieces_authorized
      self.max_expense_pieces_authorized = subscription.max_expense_pieces_authorized
      self.max_paperclips_authorized = subscription.max_paperclips_authorized
      self.max_oversized_authorized = subscription.max_oversized_authorized
      self.unit_price_of_excess_sheet = subscription.unit_price_of_excess_sheet
      self.price_of_a_lot_of_upload = subscription.price_of_a_lot_of_upload
      self.unit_price_of_excess_preseizure = subscription.unit_price_of_excess_preseizure
      self.unit_price_of_excess_expense = subscription.unit_price_of_excess_expense
      self.unit_price_of_excess_paperclips = subscription.unit_price_of_excess_paperclips
      self.unit_price_of_excess_oversized = subscription.unit_price_of_excess_oversized
      self.copy_to_options! subscription.product_option_orders
      self.save
    end
  end
end
