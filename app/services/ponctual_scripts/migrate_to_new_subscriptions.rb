class PonctualScripts::MigrateToNewSubscriptions < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private 

  def execute
    updated_lists = []

    Subscription.where('user_id > 0').each do |subscription|
      @subscription = subscription
      next unless @subscription.configured? && @subscription.user && @subscription.user.still_active?

      prepare_params

      prepare_mail   if subscription.is_mail_package_active
      prepare_box    if subscription.is_scan_box_package_active
      prepare_annual if subscription.is_annual_package_active

      if @has_changed
        logger_infos "[MigrateSubscriptions] - subscription ID : #{subscription.id.to_s}"
        save_subscription
        migrate_subscription
        updated_lists << subscription.to_json
      end
    end

    if updated_lists.present?
      log_document = {
        name: "MigrateToNewSubscriptions",
        error_group: "[PonctualScripts] Migration to new subscription",
        erreur_type: "Migration to new subscription",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          updated_lists: updated_lists.join(',')
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    end

    @file.try(:close)
  end

  def backup
    file = File.join(ponctual_dir, "subscriptions.txt")

    File.foreach(file) do |line|
      @params_update = JSON.parse(line).with_indifferent_access
      @params_update[:is_to_apply_now] = true
      @subscription = Subscription.find @params_update[:id]

      migrate_subscription
    end
  end

  def save_subscription
    @file = File.open(File.join(ponctual_dir, "subscriptions.txt"), 'w+') unless @file

    @file.write(@subscription.to_json + "\n")
  end

  def prepare_params
    @has_changed                                         = false
    @params_update                                       = {}
    @params_update[:is_to_apply_now]                     = true

    @params_update[:is_basic_package_active]             = @subscription.is_basic_package_active
    @params_update[:is_mail_package_active]              = @subscription.is_mail_package_active
    @params_update[:is_scan_box_package_active]          = @subscription.is_scan_box_package_active
    @params_update[:is_retriever_package_active]         = @subscription.is_retriever_package_active
    @params_update[:is_mini_package_active]              = @subscription.is_mini_package_active
    @params_update[:is_annual_package_active]            = @subscription.is_annual_package_active
    @params_update[:is_micro_package_active]             = @subscription.is_micro_package_active

    @params_update[:unit_price_of_excess_sheet]          = @subscription.unit_price_of_excess_sheet.to_s
    @params_update[:max_upload_pages_authorized]         = @subscription.max_upload_pages_authorized.to_s
    @params_update[:max_sheets_authorized]               = @subscription.max_sheets_authorized.to_s
    @params_update[:unit_price_of_excess_upload]         = @subscription.unit_price_of_excess_upload.to_s
    @params_update[:max_dematbox_scan_pages_authorized]  = @subscription.max_dematbox_scan_pages_authorized.to_s
    @params_update[:unit_price_of_excess_dematbox_scan]  = @subscription.unit_price_of_excess_dematbox_scan.to_s
    @params_update[:max_preseizure_pieces_authorized]    = @subscription.max_preseizure_pieces_authorized.to_s
    @params_update[:unit_price_of_excess_preseizure]     = @subscription.unit_price_of_excess_preseizure.to_s
    @params_update[:max_paperclips_authorized]           = @subscription.max_paperclips_authorized.to_s
    @params_update[:max_oversized_authorized]            = @subscription.max_oversized_authorized.to_s
    @params_update[:max_expense_pieces_authorized]       = @subscription.max_expense_pieces_authorized.to_s
    @params_update[:unit_price_of_excess_oversized]      = @subscription.unit_price_of_excess_oversized.to_s
    @params_update[:unit_price_of_excess_expense]        = @subscription.unit_price_of_excess_expense.to_s
    @params_update[:unit_price_of_excess_paperclips]     = @subscription.unit_price_of_excess_paperclips.to_s

    @params_update[:is_pre_assignment_active]            = @subscription.is_pre_assignment_active
  end

  def prepare_annual
    @has_changed                                = true
    @params_update[:is_basic_package_active]    = false
    @params_update[:is_scan_box_package_active] = false
    @params_update[:is_mail_package_active]     = true
    @params_update[:is_micro_package_active]    = true
    @params_update[:is_mini_package_active]     = false
    @params_update[:is_annual_package_active]   = false
  end

  def prepare_mail
    @has_changed                                = true
    @params_update[:is_basic_package_active]    = !@subscription.is_micro_package_active && !@subscription.is_mini_package_active
    @params_update[:is_scan_box_package_active] = false
    @params_update[:is_mail_package_active]     = true
    @params_update[:is_annual_package_active]   = false
  end

  def prepare_box
    @has_changed                                = true
    @params_update[:is_basic_package_active]    = !@subscription.is_micro_package_active && !@subscription.is_mini_package_active
    @params_update[:is_scan_box_package_active] = false
    @params_update[:is_annual_package_active]   = false
  end

  def migrate_subscription
    params = ActionController::Parameters.new(@params_update)

    SubscriptionForm.new(@subscription, requester).submit(params)
  end

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts/migrate_subscriptions"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end

  def requester
    collab = User.find_by_email 'mina@idocus.com'
    Collaborator.new collab
  end
end