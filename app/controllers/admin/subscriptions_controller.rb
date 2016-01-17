# -*- encoding : UTF-8 -*-
class Admin::SubscriptionsController < Admin::AdminController
  def index
    @subscription_options = SubscriptionOption.by_position
  end
end
