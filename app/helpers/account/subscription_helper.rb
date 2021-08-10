# frozen_string_literal: true

module Account::SubscriptionHelper
  def notify_warning(subscription, package, option='', only=false)
    if subscription
      if option.blank?
        if %w(retriever_option digitize_option).include?(package.to_s)
          package_size = subscription.current_packages.tr('["\]','   ').tr('"', '').split(',').size

          package_size == 1 && subscription.is_package?(package) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && !@subscription.futur_packages.include?(package)

          if only
            subscription.is_package?(package) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && !@subscription.futur_packages.include?(package) && !@subscription.is_package?('ido_x') && !@subscription.is_package?('ido_nano') && !@subscription.is_package?('ido_micro') && !@subscription.is_package?('ido_classique')
          end
        else
          subscription.is_package?(package) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && !@subscription.futur_packages.include?(package)
        end
      else
        if package == 'retriever_option' && option == 'digitize_option' && only
          subscription.is_package?(package) && subscription.is_package?(option) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && !@subscription.futur_packages.include?(package) && !@subscription.futur_packages.include?(option) && !@subscription.is_package?('ido_x') && !@subscription.is_package?('ido_nano') && !@subscription.is_package?('ido_micro') && !@subscription.is_package?('ido_classique')
        else
          subscription.is_package?(package) && subscription.is_package?(option) && @subscription.futur_packages.present? && @subscription.futur_packages != "[]" && @subscription.futur_packages.include?(package) && !@subscription.futur_packages.include?(option)
        end
      end
    else
      false
    end
  end
end

