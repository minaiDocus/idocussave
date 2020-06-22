# frozen_string_literal: true

class SubscriptionForm
  def initialize(subscription, requester = nil, request = nil)
    @subscription = subscription
    @requester    = requester
    @request      = request
  end

  def submit(params)
    @to_apply_now = @subscription.user.recently_created? || (@requester.is_admin && get_param(:is_to_apply_now).to_i == 1)
    is_new = !@subscription.configured?

    @subscription.is_basic_package_to_be_disabled = (!@to_apply_now && @subscription.is_basic_package_active && get_param(:is_basic_package_active).to_i == 0)
    @subscription.is_idox_package_to_be_disabled = (!@to_apply_now && @subscription.is_idox_package_active && get_param(:is_idox_package_active).to_i == 0)
    @subscription.is_micro_package_to_be_disabled = (!@to_apply_now && @subscription.is_micro_package_active && get_param(:is_micro_package_active).to_i == 0)
    @subscription.is_mini_package_to_be_disabled  = (!@to_apply_now && @subscription.is_mini_package_active  && get_param(:is_mini_package_active).to_i == 0)

    @subscription.is_mail_package_to_be_disabled  = (!@to_apply_now && @subscription.is_mail_package_active  && get_param(:is_mail_package_active).to_i == 0)
    @subscription.is_retriever_package_to_be_disabled  = (!@to_apply_now && @subscription.is_retriever_package_active && get_param(:is_retriever_package_active).to_i == 0)

    @subscription.is_basic_package_active = value_of(:is_basic_package_active) unless value_of(:is_basic_package_active).nil?
    @subscription.is_idox_package_active  = value_of(:is_idox_package_active)  unless value_of(:is_idox_package_active).nil?
    @subscription.is_mini_package_active  = value_of(:is_mini_package_active)  unless value_of(:is_mini_package_active).nil?
    @subscription.is_micro_package_active = value_of(:is_micro_package_active) unless value_of(:is_micro_package_active).nil?

    @subscription.is_mail_package_active      = value_of(:is_mail_package_active) unless value_of(:is_mail_package_active).nil?
    @subscription.is_retriever_package_active = value_of(:is_retriever_package_active) unless value_of(:is_retriever_package_active).nil?

    @subscription.period_duration = 1
    @subscription.is_pre_assignment_active = true

    @subscription.number_of_journals = get_params(:number_of_journals) if get_param(:number_of_journals).to_i > @subscription.user.account_book_types.count

    set_prices_and_limits

    set_special_excess_values

    if @subscription.configured? && @subscription.to_be_configured? && @subscription.save
      EvaluateSubscription.new(@subscription, @requester, @request).execute
      PeriodBillingService.new(@subscription.current_period).fill_past_with_0 if is_new
      UpdatePeriod.new(@subscription.current_period).execute
      destroy_pending_orders_if_needed
      true
    else
      false
    end
  end

  private

  def set_prices_and_limits
    excess_data = SubscriptionPackage.excess_of(@subscription.current_active_package)

    values = {
      max_upload_pages_authorized: excess_data[:pieces][:limit],
      unit_price_of_excess_upload: excess_data[:pieces][:price],

      max_preseizure_pieces_authorized: excess_data[:preassignments][:limit],
      unit_price_of_excess_preseizure: excess_data[:preassignments][:price],

      max_expense_pieces_authorized: excess_data[:preassignments][:limit],
      unit_price_of_excess_expense: excess_data[:preassignments][:price]
    }

    @subscription.assign_attributes(_params)

    # NOTE: this is not used now, pending dev ...
    # if @requester.is_admin
    #   _params = params.permit(
    #     { option_ids: [] },
    #     :max_sheets_authorized,
    #     :unit_price_of_excess_sheet,
    #     :max_upload_pages_authorized,
    #     :unit_price_of_excess_upload,
    #     :max_dematbox_scan_pages_authorized,
    #     :unit_price_of_excess_dematbox_scan,
    #     :max_preseizure_pieces_authorized,
    #     :unit_price_of_excess_preseizure,
    #     :max_expense_pieces_authorized,
    #     :unit_price_of_excess_expense,
    #     :max_paperclips_authorized,
    #     :unit_price_of_excess_paperclips,
    #     :max_oversized_authorized,
    #     :unit_price_of_excess_oversized
    #   )
    #   @subscription.assign_attributes(_params)
    # end
  end

  def set_special_excess_values
    if @subscription.is_mini_package_active
      values = {
        max_upload_pages_authorized: 600,
        max_preseizure_pieces_authorized: 300,
        max_expense_pieces_authorized: 300
      }

      @subscription.assign_attributes(values)
    end
  end

  def destroy_pending_orders_if_needed
    customer = @subscription.user
    return false unless customer

    unless @subscription.is_mail_package_active
      paper_set_orders = customer.orders.paper_sets.pending
      paper_set_orders.each { |order| DestroyOrder.new(order).execute } if paper_set_orders.any?
    end

    unless @subscription.is_scan_box_package_active
      dematbox_orders = customer.orders.dematboxes.pending
      dematbox_orders.each { |order| DestroyOrder.new(order).execute } if dematbox_orders.any?
    end
  end

  def value_of(package_selector)
    return true  if get_param(package_selector).to_i == 1
    return false if get_param(package_selector).to_i == 0 && @to_apply_now

    nil
  end

  def get_param(pr)
    params[pr].to_s.gsub('true', '1').gsub('false', '0')
  end
end
