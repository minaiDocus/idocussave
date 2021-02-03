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

      current_package = []
      futur_package   = []

      current_package << 'ido_x'                   if subscription.is_idox_package_active
      current_package << 'ido_micro'               if subscription.is_micro_package_active
      current_package << 'ido_mini'                if subscription.is_mini_package_active
      current_package << 'ido_classique'           if subscription.is_basic_package_active
      current_package << 'mail_option'             if subscription.is_mail_package_active
      current_package << 'retriever_option'        if subscription.is_retriever_package_active
      current_package << 'pre_assignment_option'   if subscription.is_pre_assignment_active

      futur_package << 'ido_x'                     if subscription.is_idox_package_active && !subscription.is_idox_package_to_be_disabled
      futur_package << 'ido_micro'                 if subscription.is_micro_package_active && !subscription.is_micro_package_to_be_disabled
      futur_package << 'ido_mini'                  if subscription.is_mini_package_active && !subscription.is_mini_package_to_be_disabled
      futur_package << 'ido_classique'             if subscription.is_basic_package_active && !subscription.is_basic_package_to_be_disabled
      futur_package << 'mail_option'               if subscription.is_mail_package_active && !subscription.is_mail_package_to_be_disabled
      futur_package << 'retriever_option'          if subscription.is_retriever_package_active && !subscription.is_retriever_package_to_be_disabled
      futur_package << 'pre_assignment_option'     if subscription.is_pre_assignment_active && !subscription.is_pre_assignment_to_be_disabled

      subscription.current_packages = current_package
      subscription.futur_packages   = futur_package

      subscription.save
    end
  end

  def backup
  end
end