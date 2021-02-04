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

      period_packages = subscription.current_period.current_packages

      futur_package << 'ido_x'                     if subscription.is_idox_package_active && !period_packages.include?('ido_x') && !subscription.is_idox_package_to_be_disabled
      futur_package << 'ido_micro'                 if subscription.is_micro_package_active && !period_packages.include?('ido_micro') && !subscription.is_micro_package_to_be_disabled
      futur_package << 'ido_mini'                  if subscription.is_mini_package_active && !period_packages.include?('ido_mini') && !subscription.is_mini_package_to_be_disabled
      futur_package << 'ido_classique'             if subscription.is_basic_package_active && !period_packages.include?('ido_classique') && !subscription.is_basic_package_to_be_disabled
      futur_package << 'mail_option'               if subscription.is_mail_package_active && !period_packages.include?('mail_option') && !subscription.is_mail_package_to_be_disabled
      futur_package << 'retriever_option'          if subscription.is_retriever_package_active && !period_packages.include?('retriever_option') && !subscription.is_retriever_package_to_be_disabled
      futur_package << 'pre_assignment_option'     if subscription.is_pre_assignment_active && !period_packages.include?('pre_assignment_option') && !subscription.is_pre_assignment_to_be_disabled

      subscription.current_packages = period_packages
      subscription.futur_packages   = futur_package.any? ? futur_package : nil

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