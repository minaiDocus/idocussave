# -*- encoding : UTF-8 -*-
class RemoveNotReusableOptionsService
  def initialize(subscription)
    @subscription = subscription
  end

  def execute
    @subscription.options = @subscription.options.select { |option| option.duration == 0 }
    @subscription.save
  end
end
