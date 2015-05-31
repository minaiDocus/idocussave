# -*- encoding : UTF-8 -*-
class UpdateSubscriptionService
  class << self
    def execute(subscription_id, params, requester_id, request=nil)
      subscription = Subscription.find subscription_id
      requester = User.find requester_id
      new(subscription, params, requester, request).execute
    end
    handle_asynchronously :execute, priority: 0
  end

  def initialize(subscription, params, requester, request=nil)
    @subscription = subscription
    @params       = params
    @requester    = requester
    @request      = request
  end

  def execute
    @subscription.previous_option_ids = @subscription.options.map(&:id)
    @subscription.update(@params)
    EvaluateSubscriptionService.execute(@subscription, @requester, @request) unless @subscription.organization
    UpdatePeriodService.new(@subscription.current_period).execute
  end
end
