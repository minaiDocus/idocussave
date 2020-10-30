# -*- encoding : UTF-8 -*-
# Update a subscription with parameters
class Subscription::Update
  def self.execute(subscription_id, params, requester_id, request = nil)
    requester     = User.find(requester_id)
    subscription  = Subscription.find(subscription_id)

    new(subscription, params, requester, request).execute
  end


  def initialize(subscription, params, requester, request = nil)
    @params       = params
    @request      = request
    @requester    = requester
    @subscription = subscription
  end


  def execute
    if @subscription.update(@params)
      Billing::UpdatePeriod.new(@subscription.current_period).execute # Update current period with new subscription informations
      Subscription::Evaluate.new(@subscription, @requester, @request).execute # Assign proper rights to requester

      true
    else
      false
    end
  end
end
