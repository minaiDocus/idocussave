class CreateCustomer
  attr_reader :customer

  def initialize(organization, requester, params)
    @customer = User.new params
    @customer.set_random_password
    @customer.skip_confirmation!
    if @customer.save
      UserOptions.create(user_id: @customer.id)
      source = (organization.is_journals_management_centralized || requester.is_admin) ? organization : requester
      @customer.account_book_types = source.account_book_types.default
      organization.members << @customer
      subscription = @customer.find_or_create_scan_subscription
      requester_subscription = requester.find_or_create_scan_subscription
      subscription.extend NewSubscription
      subscription.copy requester_subscription
      AccountingPlan.create(user_id: @customer.id)
      @customer.authd_prev_period            = organization.authd_prev_period
      @customer.auth_prev_period_until_day   = organization.auth_prev_period_until_day
      @customer.auth_prev_period_until_month = organization.auth_prev_period_until_month
      @customer.save && subscription.save
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
