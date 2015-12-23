# -*- encoding : UTF-8 -*-
class ReopenSubscription
  def initialize(user, requester)
    @user = user
    @subscription = @user.subscription
    @requester = requester
  end

  def execute
    @user.inactive_at = nil
    @subscription.previous_option_ids = @subscription.options.map(&:id)
    EvaluateSubscriptionService.execute(@subscription, @requester)
    UpdatePeriodService.new(@subscription.current_period).execute
    @user.find_or_create_external_file_storage
    @user.save
  end
end
