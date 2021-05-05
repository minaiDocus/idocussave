# -*- encoding : UTF-8 -*-
class Subscription::Downgrade
  def initialize(subscription, update = true)
    @update = update
    @subscription = subscription
  end

  def execute
    @subscription.options = @subscription.options.select{ |option| option.period_duration == 0 }

    @subscription.current_packages = @subscription.futur_packages if @subscription.futur_packages && @subscription.futur_packages != '[]'
    @subscription.futur_packages   = nil
    @subscription.save

    if @update
      Subscription::Evaluate.new(@subscription.reload).execute unless @subscription.organization

      Billing::UpdatePeriod.new(@subscription.reload.current_period).execute
    end
  end
end
