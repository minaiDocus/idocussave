class PonctualScripts::MigrateCustomersSubscriptions < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private 

  def execute
    tab_customers = get_customers

    tab_customers.each do |customer|
      subscription = Subscription.where(user_id: get_user_id(customer)).first  

      params_backup                                        = {}
      params_backup['id']                                  = subscription.id
      params_backup['is_basic_package_active']             = subscription.is_basic_package_active
      params_backup['is_mail_package_active']              = subscription.is_mail_package_active
      params_backup['is_scan_box_package_active']          = subscription.is_scan_box_package_active
      params_backup['is_retriever_package_active']         = subscription.is_retriever_package_active
      params_backup['is_mini_package_active']              = subscription.is_mini_package_active
      params_backup['is_annual_package_active']            = subscription.is_annual_package_active
      params_backup['is_basic_package_to_be_disabled']     = subscription.is_basic_package_to_be_disabled
      params_backup['is_mail_package_to_be_disabled']      = subscription.is_mail_package_to_be_disabled
      params_backup['is_scan_box_package_to_be_disabled']  = subscription.is_scan_box_package_to_be_disabled
      params_backup['is_retriever_package_to_be_disabled'] = subscription.is_retriever_package_to_be_disabled
      params_backup['is_pre_assignment_to_be_disabled']    = subscription.is_pre_assignment_to_be_disabled
      params_backup['is_micro_package_to_be_disabled']     = subscription.is_micro_package_to_be_disabled
      params_backup['is_micro_package_active']             = subscription.is_micro_package_active
      params_backup['is_pre_assignment_active']            = subscription.is_pre_assignment_active

      params_update                                       = {}
      params_update[:is_basic_package_active]             = false
      params_update[:is_mail_package_active]              = false
      params_update[:is_scan_box_package_active]          = false
      params_update[:is_retriever_package_active]         = false
      params_update[:is_mini_package_active]              = false
      params_update[:is_annual_package_active]            = false
      params_update[:is_basic_package_to_be_disabled]     = false
      params_update[:is_mail_package_to_be_disabled]      = false
      params_update[:is_scan_box_package_to_be_disabled]  = false
      params_update[:is_retriever_package_to_be_disabled] = false
      params_update[:is_micro_package_to_be_disabled]     = false
      params_update[:is_micro_package_active]             = true
      params_update[:is_pre_assignment_active]            = subscription.is_pre_assignment_active
      params_update[:is_pre_assignment_to_be_disabled]    = subscription.is_retriever_package_to_be_disabled

      SubscriptionForm.new(subscription, requester).submit(params_update)

      File.write(File.join(ponctual_dir, "#{customer}.json"), params_backup.to_json)
    end
  end

  def backup
    tab_customers = get_customers

    tab_customers.each do |customer|
      params = JSON.parse(File.read(File.join(ponctual_dir, "#{customer}.json"))).with_indifferent_access

      subscription = Subscription.find params[:id]

      subscription.is_basic_package_active             = params[:is_basic_package_active]
      subscription.is_mail_package_active              = params[:is_mail_package_active]
      subscription.is_scan_box_package_active          = params[:is_scan_box_package_active]
      subscription.is_retriever_package_active         = params[:is_retriever_package_active]
      subscription.is_mini_package_active              = params[:is_mini_package_active]
      subscription.is_annual_package_active            = params[:is_annual_package_active]
      subscription.is_basic_package_to_be_disabled     = params[:is_basic_package_to_be_disabled]
      subscription.is_mail_package_to_be_disabled      = params[:is_mail_package_to_be_disabled]
      subscription.is_scan_box_package_to_be_disabled  = params[:is_scan_box_package_to_be_disabled]
      subscription.is_retriever_package_to_be_disabled = params[:is_retriever_package_to_be_disabled]
      subscription.is_pre_assignment_to_be_disabled    = params[:is_pre_assignment_to_be_disabled]
      subscription.is_micro_package_to_be_disabled     = params[:is_micro_package_to_be_disabled]
      subscription.is_micro_package_active             = params[:is_micro_package_active]
      subscription.is_pre_assignment_active            = params[:is_pre_assignment_active]


      if subscription.save
        EvaluateSubscription.new(subscription, requester).execute

        UpdatePeriod.new(subscription.current_period).execute
      else
         logger_infos "[MigrateCustomersSubscriptions] - customer: #{customer.to_s} - subscription ID : #{subscription.id.to_s}"
      end
    end
  end

  def get_user_id(code)
    User.find_by_code(code).try(:id) || nil
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