class PonctualScripts::MigrateCustomersSubscriptions < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private 

  def execute
    get_customers.each do |customer|
      customer = customer.strip
      subscription = get_user(customer).try(:subscription)

      if !subscription || subscription.try(:heavy_package?)
        logger_infos "[MigrateCustomersSubscriptions] - customer: #{customer.to_s} - subscription ID : #{subscription.id.to_s} - can't be updated"
        next
      end

      params_update                                       = {}
      params_update[:is_basic_package_active]             = false
      params_update[:is_mail_package_active]              = false
      params_update[:is_scan_box_package_active]          = false
      params_update[:is_retriever_package_active]         = false
      params_update[:is_mini_package_active]              = false
      params_update[:is_annual_package_active]            = false
      params_update[:is_micro_package_active]             = true
      params_update[:is_pre_assignment_active]            = subscription.is_pre_assignment_active

      File.write(File.join(ponctual_dir, "#{customer}.json"), subscription.to_json)

      SubscriptionForm.new(subscription, requester).submit(params_update)
    end
  end

  def backup
    get_customers.each do |customer|
      customer = customer.strip
      params = JSON.parse(File.read(File.join(ponctual_dir, "#{customer}.json"))).with_indifferent_access

      subscription = Subscription.find params[:id]

      subscription.assign_attributes(params)

      if subscription.save
        EvaluateSubscription.new(subscription, requester).execute

        UpdatePeriod.new(subscription.current_period).execute
      else
         logger_infos "[MigrateCustomersSubscriptions] - customer: #{customer.to_s} - subscription ID : #{subscription.id.to_s} - rollback failed"
      end
    end
  end

  def get_user(code)
    User.find_by_code(code.strip) || nil
  end

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts/migrate_subscriptions"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end

  def get_customers
    file_path = File.join(ponctual_dir, "customers_lists.txt")
    File.read(file_path).split(',')
  end

  def requester
    User.find_by_email 'bweinberger-fidalex@extentis.fr'
  end
end