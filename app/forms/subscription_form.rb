# -*- encoding : UTF-8 -*-
class SubscriptionForm
  def initialize(subscription, requester=nil, request=nil)
    @subscription = subscription
    @requester    = requester
    @request      = request
  end

  def submit(params)
    dont_apply_now = !(@subscription.user.recently_created? || (@requester.is_admin && params[:is_to_apply_now] == '1'))
    is_new = !@subscription.configured?

    if @subscription.configured?
      if @subscription.light_package?
        if @subscription.is_basic_package_active && dont_apply_now
          @subscription.is_basic_package_to_be_disabled     = params[:is_basic_package_active]     == '0'
        else
          @subscription.is_basic_package_active             = params[:is_basic_package_active]     == '1'
          @subscription.is_basic_package_to_be_disabled     = false if @subscription.is_basic_package_to_be_disabled
        end

        if @subscription.is_mail_package_active && dont_apply_now
          @subscription.is_mail_package_to_be_disabled      = params[:is_mail_package_active]      == '0'
        else
          @subscription.is_mail_package_active              = params[:is_mail_package_active]      == '1'
          @subscription.is_mail_package_to_be_disabled      = false if @subscription.is_mail_package_to_be_disabled
        end

        if @subscription.is_scan_box_package_active && dont_apply_now
          @subscription.is_scan_box_package_to_be_disabled  = params[:is_scan_box_package_active]  == '0'
        else
          @subscription.is_scan_box_package_active          = params[:is_scan_box_package_active]  == '1'
          @subscription.is_scan_box_package_to_be_disabled  = false if @subscription.is_scan_box_package_to_be_disabled
        end

        if @subscription.is_retriever_package_active && dont_apply_now
          @subscription.is_retriever_package_to_be_disabled = params[:is_retriever_package_active] == '0'
        else
          @subscription.is_retriever_package_active         = params[:is_retriever_package_active] == '1'
          @subscription.is_retriever_package_to_be_disabled = false if @subscription.is_retriever_package_to_be_disabled
        end
      end
    else
      if params[:is_annual_package_active] == '1'
        @subscription.is_annual_package_active    = true
        @subscription.is_basic_package_active     = false
        @subscription.is_mail_package_active      = false
        @subscription.is_scan_box_package_active  = false
        @subscription.is_retriever_package_active = false
        @subscription.period_duration             = 12
      else
        @subscription.is_annual_package_active    = false
        @subscription.is_basic_package_active     = params[:is_basic_package_active]     == '1'
        @subscription.is_mail_package_active      = params[:is_mail_package_active]      == '1'
        @subscription.is_scan_box_package_active  = params[:is_scan_box_package_active]  == '1'
        @subscription.is_retriever_package_active = params[:is_retriever_package_active] == '1'
        @subscription.period_duration             = params[:period_duration]
      end
    end
    if params[:number_of_journals].to_i > @subscription.user.account_book_types.count
      @subscription.number_of_journals = params[:number_of_journals]
    end

    if @subscription.is_scan_box_package_active
      if @subscription.is_blank_page_remover_active && dont_apply_now
        @subscription.is_blank_page_remover_to_be_disabled = params[:is_blank_page_remover_active] == 'false'
      else
        @subscription.is_blank_page_remover_active = params[:is_blank_page_remover_active] == 'true'
        @subscription.is_blank_page_remover_to_be_disabled = false if @subscription.is_blank_page_remover_to_be_disabled
      end
    else
      @subscription.is_blank_page_remover_active = false
    end

    if @subscription.is_basic_package_active || @subscription.is_mail_package_active || @subscription.is_scan_box_package_active
      if @subscription.is_pre_assignment_active && dont_apply_now
        @subscription.is_pre_assignment_to_be_disabled = params[:is_pre_assignment_active] == 'false'
      else
        @subscription.is_pre_assignment_active = params[:is_pre_assignment_active] == 'true'
        @subscription.is_pre_assignment_to_be_disabled = false if @subscription.is_pre_assignment_to_be_disabled
      end
    else
      @subscription.is_pre_assignment_active = false
    end

    if @subscription.is_mail_package_active
      if @subscription.is_stamp_active && dont_apply_now
        @subscription.is_stamp_to_be_disabled = params[:is_stamp_active] == 'false'
      else
        @subscription.is_stamp_active = params[:is_stamp_active] == 'true'
        @subscription.is_stamp_to_be_disabled = false if @subscription.is_stamp_to_be_disabled
      end
    else
      @subscription.is_stamp_active = false
    end

    if @requester.is_admin
      _params = params.permit(
        { option_ids: [] },
        :max_sheets_authorized,
        :unit_price_of_excess_sheet,
        :max_upload_pages_authorized,
        :unit_price_of_excess_upload,
        :max_dematbox_scan_pages_authorized,
        :unit_price_of_excess_dematbox_scan,
        :max_preseizure_pieces_authorized,
        :unit_price_of_excess_preseizure,
        :max_expense_pieces_authorized,
        :unit_price_of_excess_expense,
        :max_paperclips_authorized,
        :unit_price_of_excess_paperclips,
        :max_oversized_authorized,
        :unit_price_of_excess_oversized
      )
      @subscription.assign_attributes(_params)
    end

    if @subscription.configured? && @subscription.to_be_configured? && @subscription.save
      EvaluateSubscription.new(@subscription, @requester, @request).execute
      PeriodBillingService.new(@subscription.current_period).fill_past_with_0 if is_new
      UpdatePeriod.new(@subscription.current_period).execute
      true
    else
      false
    end
  end
end
