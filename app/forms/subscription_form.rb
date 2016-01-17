# -*- encoding : UTF-8 -*-
class SubscriptionForm
  def initialize(subscription, requester=nil, request=nil)
    @subscription = subscription
    @requester    = requester
    @request      = request
  end

  def submit(params)
    if @subscription.configured?
      if @subscription.light_package?
        unless @subscription.is_basic_package_active
          @subscription.is_basic_package_active     = params[:is_basic_package_active]     == '1'
        end
        unless @subscription.is_mail_package_active
          @subscription.is_mail_package_active      = params[:is_mail_package_active]      == '1'
        end
        unless @subscription.is_scan_box_package_active
          @subscription.is_scan_box_package_active  = params[:is_scan_box_package_active]  == '1'
        end
        unless @subscription.is_retriever_package_active
          @subscription.is_retriever_package_active = params[:is_retriever_package_active] == '1'
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
    if params[:number_of_journals].to_i > @subscription.number_of_journals
      @subscription.number_of_journals = params[:number_of_journals]
    end
    if @subscription.is_scan_box_package_active && !@subscription.is_blank_page_remover_active
      @subscription.is_blank_page_remover_active = params[:is_blank_page_remover_active] == 'true'
    end
    if @subscription.is_basic_package_active || @subscription.is_mail_package_active || @subscription.is_scan_box_package_active
      unless @subscription.is_pre_assignment_active
        @subscription.is_pre_assignment_active = params[:is_pre_assignment_active] == 'true'
      end
    end
    if @subscription.is_mail_package_active && !@subscription.is_stamp_active
      @subscription.is_stamp_active = params[:is_stamp_active] == 'true'
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

    if @subscription.save && @subscription.configured?
      EvaluateSubscription.new(@subscription, @requester, @request).execute
      UpdatePeriod.new(@subscription.current_period).execute
      true
    else
      false
    end
  end
end
