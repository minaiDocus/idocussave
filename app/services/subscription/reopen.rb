# -*- encoding : UTF-8 -*-
# Re-activate a user who has previously been disabled
class Subscription::Reopen
  def initialize(user, requester, request = nil)
    @user         = user
    @request      = request
    @requester    = requester
    @subscription = @user.subscription
  end


  def execute
    @user.inactive_at = nil
    @user.options.max_number_of_journals = 5
    @user.save

    @subscription.update_attributes(start_date: nil, end_date: nil)
    @subscription.reload

    Subscription::Evaluate.new(@subscription, @requester, @request).execute

    Billing::UpdatePeriod.new(@subscription.current_period).execute

    @user.find_or_create_external_file_storage

    @user.save
  end
end
