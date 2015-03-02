# -*- encoding : UTF-8 -*-
class UpdateSubscriptionService
  def initialize(subscription, params, requester)
    @subscription = subscription
    @params       = params
    @requester    = requester
  end

  def execute
    @subscription.previous_option_ids = @subscription.options.map(&:id)
    @subscription.update_attributes(@params)
    EvaluateSubscriptionService.execute(@subscription, @requester) unless @subscription.organization
    UpdatePeriodService.new(@subscription.current_period).execute
  end
end
