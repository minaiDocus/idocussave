class PonctualScripts::UpdateStepCustomersConfiguration < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    if File.exist?(save_file_path)
      logger_infos "[UpdateUserConfigurationStep] - Save file already exist : #{save_file_path}"
      return false
    end

    updated_lists = []

    User.where('current_configuration_step IS NOT NULL OR last_configuration_step IS NOT NULL').each do |user|
      next if user.current_configuration_step == 'subscription'

      @user = user

      logger_infos "[UpdateStepCustomersConfiguration] - user ID : #{user.id.to_s}"
      save_udpate_to_file
      updated_lists << { user: @user, current_configuration_step: user.current_configuration_step, last_configuration_step: user.last_configuration_step }
      update_step_configuration
    end

    if updated_lists.present?
      raw_table = "User updated : (#{updated_lists.size}) : <br/><table style='border: 1px solid #CCC;font-family: \"Open Sans\", sans-serif; font-size:12px;'>"
      raw_table += "<tr>"

      raw_table += "<th>ID</th>"
      raw_table += "<th>Code</th>"
      raw_table += "<th>current_configuration_step</th>"
      raw_table += "<th>last_configuration_step</th>"

      raw_table += "</tr><tbody>"

      updated_lists.each do |hassh|
        user  = hassh[:user]
        cstep = hassh[:current_configuration_step]
        lstep = hassh[:last_configuration_step]

        raw_table += "<tr>"
        raw_table += "<td>#{user.id.to_s}<td>"
        raw_table += "<td>#{user.code.to_s}<td>"
        raw_table += "<td>#{cstep.to_s}<td>"
        raw_table += "<td>#{lstep.to_s}<td>"
        raw_table += "</tr>"
      end

      raw_table += "<tbody><table>"

      log_document = {
        subject: "[PonctualScripts::UpdateStepCustomersConfiguration] update step customers configuration",
        name: "UpdateStepCustomersConfiguration",
        error_group: "[PonctualScripts] Update step customers configuration",
        erreur_type: "Update step customers configuration",
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
        @user  = User.find @params_update[:id]

        update_step_configuration({ current_configuration_step: @params_update[:current_configuration_step], last_configuration_step: @params_update[:last_configuration_step] })
      end
    else
      logger_infos "[UpdateStepCustomersConfiguration] - No saved file found"
    end
  end

  def save_udpate_to_file
    @file = File.open(save_file_path, 'w+') unless @file

    @file.write(@user.to_json + "\n")
  end

  def save_file_path
    File.join(ponctual_dir, "update_step_customers_configuration.txt")
  end

  def update_step_configuration(options = { current_configuration_step: nil, last_configuration_step: nil })
    @user.current_configuration_step = options[:current_configuration_step]
    @user.last_configuration_step    = options[:last_configuration_step]

    @user.save
  end

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts/migrate_subscriptions"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end
end