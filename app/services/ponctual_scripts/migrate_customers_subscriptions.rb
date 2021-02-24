class PonctualScripts::MigrateCustomersSubscriptions < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private 

  def execute
    not_updated_lists = []

    get_customers.each do |customer|
      customer     = customer.strip
      subscription = get_user(customer).try(:subscription)

      if !subscription || subscription.try(:heavy_package?)
        logger_infos "[MigrateCustomersSubscriptions] - customer: #{customer.to_s} - subscription ID : #{subscription.try(:id).to_s} - can't be updated"
        not_updated_lists << { subscription_id: subscription.try(:id), customer: customer }
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
      params_update[:is_to_apply_now]                     = true

      params_update[:unit_price_of_excess_sheet]          = subscription.unit_price_of_excess_sheet.to_s
      params_update[:max_upload_pages_authorized]         = subscription.max_upload_pages_authorized.to_s
      params_update[:max_sheets_authorized]               = subscription.max_sheets_authorized.to_s
      params_update[:unit_price_of_excess_upload]         = subscription.unit_price_of_excess_upload.to_s
      params_update[:max_dematbox_scan_pages_authorized]  = subscription.max_dematbox_scan_pages_authorized.to_s
      params_update[:unit_price_of_excess_dematbox_scan]  = subscription.unit_price_of_excess_dematbox_scan.to_s
      params_update[:max_preseizure_pieces_authorized]    = subscription.max_preseizure_pieces_authorized.to_s
      params_update[:unit_price_of_excess_preseizure]     = subscription.unit_price_of_excess_preseizure.to_s
      params_update[:max_paperclips_authorized]           = subscription.max_paperclips_authorized.to_s
      params_update[:max_oversized_authorized]            = subscription.max_oversized_authorized.to_s
      params_update[:max_expense_pieces_authorized]       = subscription.max_expense_pieces_authorized.to_s
      params_update[:unit_price_of_excess_oversized]      = subscription.unit_price_of_excess_oversized.to_s
      params_update[:unit_price_of_excess_expense]        = subscription.unit_price_of_excess_expense.to_s
      params_update[:unit_price_of_excess_paperclips]     = subscription.unit_price_of_excess_paperclips.to_s

      params_update[:is_pre_assignment_active]            = subscription.is_pre_assignment_active

      File.write(File.join(ponctual_dir, "#{customer}.json"), subscription.to_json)

      params = ActionController::Parameters.new(params_update)

      Subscription::Form.new(subscription, requester).submit(params)
    end

    if not_updated_lists.present?
      log_document = {
        subject: "[PonctualScripts::MigrateCustomersSubscriptions] migration extentis to iDo micro",
        name: "MigrateCustomersSubscriptions",
        error_group: "[PonctualScripts] Migration Extentis to Ido micro",
        erreur_type: "Migration Extentis to Ido micro",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          not_updated_lists: not_updated_lists.join(',')
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    end
  end

  def backup
    get_customers.each do |customer|
      customer = customer.strip
      file     = File.join(ponctual_dir, "#{customer}.json")

      if !File.exist?(file)
        logger_infos "[MigrateCustomersSubscriptions] - customer: #{customer.to_s} - file not exist"
        next
      end

      params = JSON.parse(File.read(file)).with_indifferent_access

      subscription = Subscription.find params[:id]

      subscription.assign_attributes(params)

      if subscription.save
        Subscription::Evaluate.new(subscription, requester).execute

        Billing::UpdatePeriod.new(subscription.current_period).execute
      else
         logger_infos "[MigrateCustomersSubscriptions] - customer: #{customer.to_s} - subscription ID : #{subscription.id.to_s} - rollback failed"
      end
    end
  end

  def get_user(code)
    User.where(code: code.strip).active.first || nil
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
    collab = User.find_by_email 'mina@idocus.com'
    Collaborator.new collab
  end
end