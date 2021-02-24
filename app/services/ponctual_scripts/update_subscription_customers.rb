class PonctualScripts::UpdateSubscricptionCustomers < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    if File.exist?(save_file_path)
      logger_infos "[UpdateSubscricptionCustomers] - Save file already exist : #{save_file_path}"
      return false
    end

    updated_lists = []

    list_customers.each do |customer|
      @subscription = customer.subscription

      logger_infos "[UpdateSubscricptionCustomers] - subscription ID : #{@subscription.   id.to_s}"
      save_udpate_to_file

      prepare_params
      update_subscription_customers
      updated_lists << @subscription
    end

    if updated_lists.present?
      raw_table = "Subscriptions updated : (#{updated_lists.size}) : <br/><table style='border: 1px solid #CCC;font-family: \"Open Sans\", sans-serif; font-size:12px;'>"
      raw_table += "<tr>"

      Subscription.attribute_names.each do |field|
        raw_table += "<th>#{field.to_s}</th>"
      end

      raw_table += "</tr><tbody>"

      updated_lists.each do |subscription|
        raw_table += "<tr>"
          Subscription.attribute_names.each do |field|
            raw_table += "<td>#{subscription.send(field.to_sym).to_s}<td>"
          end
        raw_table += "</tr>"
      end

      raw_table += "<tbody><table>"

      log_document = {
        subject: "[PonctualScripts::UpdateSubscricptionCustomers] update subscricption customers",
        name: "UpdateSubscricptionCustomers",
        error_group: "[PonctualScripts] Update Subscricption Customers",
        erreur_type: "Update Subscricption Customers",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        raw_information: raw_table
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    end

    @file.try(:close)
  end

  def backup
    file = save_file_path

    if File.exist?(file)
      File.foreach(file) do |line|
        @params_update = JSON.parse(line).with_indifferent_access
        @params_update[:is_to_apply_now] = true
        @subscription = Subscription.find @params_update[:id]

        update_subscription_customers
      end
    else
      logger_infos "[UpdateStepCustomersConfiguration] - No saved file found"
    end
  end

  def prepare_params    
    @params_update                                       = {}
    @params_update[:is_to_apply_now]                     = true

    @params_update[:is_basic_package_active]             = false
    @params_update[:is_mail_package_active]              = @subscription.is_mail_package_active
    @params_update[:is_scan_box_package_active]          = false
    @params_update[:is_retriever_package_active]         = false
    @params_update[:is_mini_package_active]              = false
    @params_update[:is_annual_package_active]            = false
    @params_update[:is_micro_package_active]             = true

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

    @params_update[:is_pre_assignment_active]            = true
  end

  def list_customers
    customers       = []
    file            = File.join(ponctual_dir, "subscriptions_acda.txt")
    _list_customers = File.read(file).split(';')

    _list_customers.each { |customer_code| customers << User.find_by_code(customer_code) }
    
    customers
  end

  def save_udpate_to_file
    @file = File.open(save_file_path, 'w+') unless @file

    @file.write(@subscription.to_json + "\n")
  end

  def save_file_path
    File.join(ponctual_dir, "update_subscription_customers.txt")
  end

  def update_subscription_customers    
    params = ActionController::Parameters.new(@params_update)

    Subscription::Form.new(@subscription, requester).submit(params)
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