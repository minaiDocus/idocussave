# -*- encoding : UTF-8 -*-
class DowngradeSubscription
  def initialize(subscription, update = true)
    @update = update
    @subscription = subscription
  end

  def execute
    @subscription.options = @subscription.options.select { |option| option.period_duration == 0 }

    if @subscription.is_basic_package_to_be_disabled
      @subscription.is_basic_package_active         = false
      @subscription.is_basic_package_to_be_disabled = false
    end

    if @subscription.is_micro_package_to_be_disabled
      @subscription.is_micro_package_active         = false
      @subscription.is_micro_package_to_be_disabled = false
    end

    if @subscription.is_mail_package_to_be_disabled
      @subscription.is_stamp_active                = false
      @subscription.is_mail_package_active         = false
      @subscription.is_mail_package_to_be_disabled = false
    end

    if @subscription.is_scan_box_package_to_be_disabled
      @subscription.is_scan_box_package_active              = false
      @subscription.is_scan_box_package_to_be_disabled = false
    end

    if @subscription.is_retriever_package_to_be_disabled
      @subscription.is_retriever_package_active               = false
      @subscription.is_retriever_package_to_be_disabled  = false
    end

    if !@subscription.is_basic_package_active && !@subscription.is_micro_package_active && !@subscription.is_mail_package_active && !@subscription.is_scan_box_package_active && !@subscription.is_annual_package_active
      @subscription.is_pre_assignment_active = false
    end

    if @subscription.is_pre_assignment_to_be_disabled
      @subscription.is_pre_assignment_active         = false
      @subscription.is_pre_assignment_to_be_disabled = false
    end

    if @subscription.is_stamp_to_be_disabled
      @subscription.is_stamp_active         = false
      @subscription.is_stamp_to_be_disabled = false
    end

    @subscription.save

    if @update
      EvaluateSubscription.new(@subscription).execute unless @subscription.organization

      UpdatePeriod.new(@subscription.current_period).execute
    end
  end
end
