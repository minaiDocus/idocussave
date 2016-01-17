# -*- encoding : UTF-8 -*-
class ReopenSubscription
  def initialize(user, requester, request=nil)
    @user         = user
    @subscription = @user.subscription
    @requester    = requester
    @request      = request
  end

  def execute
    @user.inactive_at = nil
    @user.options.max_number_of_journals = 5
    EvaluateSubscription.new(@subscription, @requester, @request).execute
    UpdatePeriod.new(@subscription.current_period).execute
    @user.find_or_create_external_file_storage
    @user.save
  end
end
