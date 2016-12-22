# -*- encoding : UTF-8 -*-
# Re-activate a user who has previously been disabled
class ReopenSubscription
  def initialize(user, requester, request = nil)
    @user         = user
    @request      = request
    @requester    = requester
    @subscription = @user.subscription
  end


  def execute
    @user.inactive_at = nil
    @user.options.max_number_of_journals = 5

    UpdatePeriod.new(@subscription.current_period).execute
    EvaluateSubscription.new(@subscription, @requester, @request).execute

    @user.find_or_create_external_file_storage

    @user.save
  end
end
