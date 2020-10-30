module Subscription::UpdateOption
  # Updates a subscription-option then updates customer's current period
  def self.execute(subscription_option, parameters)
    if subscription_option.update(parameters)

      subscription_option.subscribers.each do |subscription|
        if subscription.owner.try(:active?)
          Billing::UpdatePeriod.new(subscription.current_period).execute
        end
      end

      true
    else
      false
    end
  end
end
