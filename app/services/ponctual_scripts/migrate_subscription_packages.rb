class PonctualScripts::MigrateSubscriptionPackages < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    Subscription.all.each do |subscription|
      next if subscription.current_packages.present?

      futur_package   = []

      next unless subscription.user && subscription.user.still_active?

      period_packages = subscription.periods.last.try(:current_packages).presence || []

      futur_package << 'ido_x'                    if subscription.is_idox_package_active  && !period_packages.include?('ido_x') && !subscription.is_idox_package_to_be_disabled
      futur_package << 'ido_micro'                if subscription.is_micro_package_active && !period_packages.include?('ido_micro') && !subscription.is_micro_package_to_be_disabled
      futur_package << 'ido_mini'                 if subscription.is_mini_package_active  && !period_packages.include?('ido_mini') && !subscription.is_mini_package_to_be_disabled
      futur_package << 'ido_classique'            if subscription.is_basic_package_active && !period_packages.include?('ido_classique') && !subscription.is_basic_package_to_be_disabled

      if futur_package.any?
        futur_package << 'mail_option'            if subscription.is_mail_package_active  && !subscription.is_mail_package_to_be_disabled
        futur_package << 'retriever_option'       if subscription.is_retriever_package_active && !subscription.is_retriever_package_to_be_disabled
        futur_package << 'pre_assignment_option'  if subscription.is_pre_assignment_active && !subscription.is_pre_assignment_to_be_disabled
      end

      futur_package << 'retriever_option'         if subscription.is_retriever_package_active && !subscription.is_retriever_package_to_be_disabled && ((subscription.is_idox_package_to_be_disabled && period_packages.include?('ido_x')) || (subscription.is_micro_package_to_be_disabled && period_packages.include?('ido_micro')) || (subscription.is_mini_package_to_be_disabled && period_packages.include?('ido_mini') ) || (subscription.is_basic_package_to_be_disabled && period_packages.include?('ido_classique')))

      subscription.current_packages = period_packages
      subscription.futur_packages   = futur_package.any? ? futur_package.uniq : nil

      subscription.save
    end
  end

  def backup
    Subscription.all.each do |subscription|
      subscription.current_packages = nil
      subscription.futur_packages   = nil

      subscription.save
    end
  end
end