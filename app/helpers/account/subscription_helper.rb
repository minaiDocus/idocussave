# frozen_string_literal: true

module Account::SubscriptionHelper
  def notify_warning(subscription, package, option='')
    if subscription
      if option.blank?
        if package == 'retriever_option'
          package_size = subscription.current_packages.tr('["\]','   ').tr('"', '').split(',').size

          package_size == 1 && subscription.is_package?(package) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && !@subscription.futur_packages.include?(package)
        else
          subscription.is_package?(package) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && !@subscription.futur_packages.include?(package)
        end
      else
        subscription.is_package?(package) && subscription.is_package?(option) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && @subscription.futur_packages.include?(package) && !@subscription.futur_packages.include?(option)
      end
    else
      false
    end
  end
end