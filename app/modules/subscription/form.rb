# frozen_string_literal: true

class Subscription::Form
  def initialize(subscription, requester = nil, request = nil)
    @subscription = subscription
    @requester    = requester
    @request      = request
  end

  def submit(params)
    current_packages  = []
    futur_packages    = []

    @params = params
    is_new  = !@subscription.configured?

    @to_apply_now = @subscription.user.recently_created? || (@requester.is_admin && get_param(:is_to_apply_now).to_i == 1)

    current_package_data = @subscription.current_packages.nil? ? [] : @subscription.current_packages.tr('["\]','   ').tr('"', '').split(',').map { |pack| pack.strip }

    if current_package_data.include?(@params[:subscription_option]) || @to_apply_now
      current_packages << @params[:subscription_option]

      current_packages << 'mail_option'             if params[:mail_option] && !current_package_data.include?(params[:mail_option])
      current_packages << 'retriever_option'        if params[:retriever_option] && !current_package_data.include?(params[:retriever_option])
      current_packages << 'pre_assignment_option'   if params[:is_pre_assignment_active] == 'true' && !current_package_data.include?(params[:is_pre_assignment_active]) && (@params[:subscription_option] == 'ido_mini' || @params[:subscription_option] == 'ido_classique')

      if current_package_data.uniq.size > current_packages.uniq.size
        futur_packages = current_packages
      elsif (current_package_data.size == 1 && !current_package_data.include?(@params[:subscription_option])) || @params[:subscription_option] == 'retriever_option'
        current_package_data = current_packages
      else
        current_package_data = current_package_data + current_packages
      end

      @to_apply_now = true
    else
      futur_packages << @params[:subscription_option]

      futur_packages << 'mail_option'             if params[:mail_option]
      futur_packages << 'retriever_option'        if params[:retriever_option] && @params[:subscription_option] != 'retriever_option'
      futur_packages << 'pre_assignment_option'   if params[:is_pre_assignment_active] == 'true' && @params[:subscription_option] != 'retriever_option' && (@params[:subscription_option] == 'ido_mini' || @params[:subscription_option] == 'ido_classique')
    end

    @subscription.current_packages = current_package_data.uniq
    @subscription.futur_packages   = futur_packages.any? ? futur_packages.uniq : nil

    if @to_apply_now && !@subscription.current_packages.include?(@params[:subscription_option])
      @subscription.current_packages = futur_packages
      @subscription.futur_packages   = nil
    end

    @subscription.period_duration = 1

    @subscription.number_of_journals = get_param(:number_of_journals) if get_param(:number_of_journals).to_i > @subscription.user.account_book_types.count

    if @subscription.configured? && @subscription.save
      @subscription.set_start_date_and_end_date

      Billing::UpdatePeriod.new(@subscription.current_period, { renew_packages: @to_apply_now }).execute
      Subscription::Evaluate.new(@subscription, @requester, @request).execute
      Billing::PeriodBilling.new(@subscription.current_period).fill_past_with_0 if is_new

      set_prices_and_limits
      set_special_excess_values

      destroy_pending_orders_if_needed
      true
    else
      false
    end
  end

  private

  def set_prices_and_limits
    excess_data = Subscription::Package.excess_of(@subscription.current_active_package)

    values = {
                max_upload_pages_authorized: excess_data[:pieces][:limit],
                unit_price_of_excess_upload: excess_data[:pieces][:price],

                max_preseizure_pieces_authorized: excess_data[:preassignments][:limit],
                unit_price_of_excess_preseizure: excess_data[:preassignments][:price],

                max_expense_pieces_authorized: excess_data[:preassignments][:limit],
                unit_price_of_excess_expense: excess_data[:preassignments][:price]
              }

    @subscription.assign_attributes(values)

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
    if @subscription.is_package?('ido_mini')
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

    unless @subscription.is_package?('mail_option')
      paper_set_orders = customer.orders.paper_sets.pending
      paper_set_orders.each { |order| Order::Destroy.new(order).execute } if paper_set_orders.any?
    end

    unless @subscription.is_package?('scan')
      dematbox_orders = customer.orders.dematboxes.pending
      dematbox_orders.each { |order| Order::Destroy.new(order).execute } if dematbox_orders.any?
    end
  end

  def value_of(package_selector)
    return true  if get_param(package_selector).to_i == 1
    return false if get_param(package_selector).to_i == 0 && @to_apply_now

    nil
  end

  def get_param(pr)
    @params[pr].to_s.gsub('true', '1').gsub('false', '0')
  end
end
