# -*- encoding : UTF-8 -*-
class UpdateSubscription
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
    if @subscription.update(@params)
      EvaluateSubscription.new(@subscription, @requester, @request).execute
      UpdatePeriod.new(@subscription.current_period).execute
      true
    else
      false
    end
  end
end
