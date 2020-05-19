# frozen_string_literal: true

class SubscriptionForm
  def initialize(subscription, requester = nil, request = nil)
    @subscription = subscription
    @requester    = requester
    @request      = request
  end

  def submit(params)
    dont_apply_now = !(@subscription.user.recently_created? || (@requester.is_admin && parse_params(params[:is_to_apply_now]).to_i == 1))
    is_new = !@subscription.configured?

    if @subscription.configured?
      if @subscription.light_package?
        if @subscription.is_basic_package_active && dont_apply_now
          @subscription.is_basic_package_to_be_disabled     = parse_params(params[:is_basic_package_active]).to_i     == 0
        else
          @subscription.is_basic_package_active             = parse_params(params[:is_basic_package_active]).to_i     == 1
          if @subscription.is_basic_package_to_be_disabled
            @subscription.is_basic_package_to_be_disabled     = false
          end
        end

        if @subscription.is_mail_package_active && dont_apply_now
          @subscription.is_mail_package_to_be_disabled      = parse_params(params[:is_mail_package_active]).to_i      == 0
        else
          @subscription.is_mail_package_active              = parse_params(params[:is_mail_package_active]).to_i      == 1
          if @subscription.is_mail_package_to_be_disabled
            @subscription.is_mail_package_to_be_disabled      = false
          end
        end

        if @subscription.is_scan_box_package_active && dont_apply_now
          @subscription.is_scan_box_package_to_be_disabled  = parse_params(params[:is_scan_box_package_active]).to_i  == 0
        else
          @subscription.is_scan_box_package_active          = parse_params(params[:is_scan_box_package_active]).to_i  == 1
          if @subscription.is_scan_box_package_to_be_disabled
            @subscription.is_scan_box_package_to_be_disabled  = false
          end
        end

        if @subscription.is_retriever_package_active && dont_apply_now
          @subscription.is_retriever_package_to_be_disabled = parse_params(params[:is_retriever_package_active]).to_i == 0
        else
          @subscription.is_retriever_package_active         = parse_params(params[:is_retriever_package_active]).to_i == 1
          if @subscription.is_retriever_package_to_be_disabled
            @subscription.is_retriever_package_to_be_disabled = false
          end
        end

        if @subscription.is_mini_package_active && dont_apply_now
          @subscription.is_mini_package_to_be_disabled      = parse_params(params[:is_mini_package_active]).to_i      == 0
        else
          @subscription.is_mini_package_active              = parse_params(params[:is_mini_package_active]).to_i      == 1
          if @subscription.is_mini_package_to_be_disabled
            @subscription.is_mini_package_to_be_disabled      = false
          end
        end

        if @subscription.is_micro_package_active && dont_apply_now
          @subscription.is_micro_package_to_be_disabled      = parse_params(params[:is_micro_package_active]).to_i      == 0
        else
          @subscription.is_micro_package_active              = parse_params(params[:is_micro_package_active]).to_i      == 1
          if @subscription.is_micro_package_to_be_disabled
            @subscription.is_micro_package_to_be_disabled = false
          end
        end
      end
    else
      if params[:is_annual_package_active].to_i == 1
        @subscription.is_annual_package_active    = true
        @subscription.is_basic_package_active     = false
        @subscription.is_mail_package_active      = false
        @subscription.is_scan_box_package_active  = false
        @subscription.is_retriever_package_active = false
        @subscription.period_duration             = 12
      elsif params[:is_micro_package_active].to_i == 1
        @subscription.is_micro_package_active     = true
        @subscription.is_annual_package_active    = false
        @subscription.is_mini_package_active      = false
        @subscription.is_basic_package_active     = false
        @subscription.is_mail_package_active      = false
        @subscription.is_scan_box_package_active  = false
        @subscription.is_retriever_package_active = false
        @subscription.period_duration             = 1
      elsif params[:is_mini_package_active].to_i == 1
        @subscription.is_mini_package_active      = true
        @subscription.is_micro_package_active     = false
        @subscription.is_annual_package_active    = false
        @subscription.is_basic_package_active     = false
        @subscription.is_mail_package_active      = false
        @subscription.is_scan_box_package_active  = false
        @subscription.is_retriever_package_active = parse_params(params[:is_retriever_package_active]).to_i == 1
        @subscription.period_duration             = 1
      else
        @subscription.is_annual_package_active    = false
        @subscription.is_basic_package_active     = parse_params(params[:is_basic_package_active]).to_i     == 1
        @subscription.is_mail_package_active      = parse_params(params[:is_mail_package_active]).to_i      == 1
        @subscription.is_scan_box_package_active  = parse_params(params[:is_scan_box_package_active]).to_i  == 1
        @subscription.is_retriever_package_active = parse_params(params[:is_retriever_package_active]).to_i == 1
        @subscription.period_duration             = 1
      end
    end

    if params[:number_of_journals].to_i > @subscription.user.account_book_types.count
      @subscription.number_of_journals = params[:number_of_journals]
    end

    if @subscription.is_basic_package_active || @subscription.is_micro_package_active || @subscription.is_mail_package_active || @subscription.is_scan_box_package_active || @subscription.is_mini_package_active
      if @subscription.is_pre_assignment_active && dont_apply_now
        @subscription.is_pre_assignment_to_be_disabled = parse_params(params[:is_pre_assignment_active]).to_i == 0
      else
        @subscription.is_pre_assignment_active = parse_params(params[:is_pre_assignment_active]).to_i == 1
        if @subscription.is_pre_assignment_to_be_disabled
          @subscription.is_pre_assignment_to_be_disabled = false
        end
      end
    else
      @subscription.is_pre_assignment_active = false
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

    set_special_excess_values

    if @subscription.configured? && @subscription.to_be_configured? && @subscription.save
      EvaluateSubscription.new(@subscription, @requester, @request).execute
      if is_new
        PeriodBillingService.new(@subscription.current_period).fill_past_with_0
      end
      UpdatePeriod.new(@subscription.current_period).execute
      true
    else
      false
    end
  end

  private

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

  def parse_params(pr)
    pr.to_s.gsub('true', '1').gsub('false', '0')
  end
end
