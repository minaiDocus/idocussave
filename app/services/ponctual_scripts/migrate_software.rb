class PonctualScripts::MigrateSoftware < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    organizations = Organization.all

    logger_infos "[MigrateSoftoware] - organizations count: #{organizations.size} - Start"

    organizations.each do |organization|
      logger_infos "[MigrateSoftoware] - organization_name: #{organization.name} - #{Time.now}"

      migrate_software_of organization

      logger_infos "[MigrateSoftoware] - organization_name: #{organization.name} - customers count: #{organization.customers.size} - #{Time.now} -Start"

      organization.customers.each do |customer|
        logger_infos "[MigrateSoftoware] - customer_company: #{customer.company} - #{Time.now} - start ..."

        migrate_softwares_setting_of customer

        logger_infos "[MigrateSoftoware] - customer_company: #{customer.company} - #{Time.now} - end"
      end

      logger_infos "[MigrateSoftoware] - organization_name #{organization.name} - End"
    end

    logger_infos "[MigrateSoftoware] - organizations count: #{organizations.size} - End"
  end

  def migrate_software_of(organization)
    Interfaces::Software::Configuration::SOFTWARES.each do |software_name|
      software  = Interfaces::Software::Configuration.softwares[software_name.to_sym].new

      next if software_name == 'my_unisoft'

      if software_name == 'ibiza'
        ibiza = Ibiza.where(organization_id: organization.id)
        if ibiza.present?
          ibiza = ibiza.last

          software.is_used                          = ibiza.try(:used?)
          software.auto_deliver                     = (ibiza.try(:is_auto_deliver) == true ? 1 : 0) || -1
          software.state                            = ibiza.state || 'none'
          software.state_2                          = ibiza.state_2 || 'none'
          software.description                      = ibiza.description
          software.description_separator            = ibiza.description_separator
          software.piece_name_format                = ibiza.piece_name_format
          software.piece_name_format_sep            = ibiza.piece_name_format_sep
          software.voucher_ref_target               = ibiza.voucher_ref_target || 'piece_number'
          software.encrypted_access_token           = ibiza.encrypted_access_token
          software.encrypted_access_token_2         = ibiza.encrypted_access_token_2
          software.is_analysis_activated            = ibiza.is_analysis_activated || -1
          software.is_analysis_to_validate          = ibiza.is_analysis_to_validate || -1
          software.is_auto_updating_accounting_plan = true
        end
      elsif software_name == 'csv_descriptor'
        csv_descriptor  = CsvDescriptor.where(organization_id: organization.id)
        if csv_descriptor
          csv_descriptor                         = csv_descriptor.first

          software.is_used                       = organization.try(:is_csv_descriptor_used)
          software.auto_deliver                  = organization.try(:is_csv_descriptor_auto_deliver) || -1
          software.comma_as_number_separator     = csv_descriptor.try(:comma_as_number_separator)
          software.directive                     = csv_descriptor.try(:directive)
        end
      else
        software.is_used      = organization.send("is_#{software_name}_used".to_sym)
        software.auto_deliver = (organization.send("is_#{software_name}_auto_deliver".to_sym) == true ? 1 : 0) || -1
      end

      software.owner = organization
      software.save
    end
  end

  def migrate_softwares_setting_of(user)
    softwares_setting     = SoftwaresSetting.find_by_user_id(user.id)

    Interfaces::Software::Configuration::SOFTWARES.each do |software_name|
      software  = Interfaces::Software::Configuration.softwares[software_name.to_sym].new

      next if software_name == 'my_unisoft' || !softwares_setting.present?

      if software_name == 'ibiza' && user.try(:ibiza_id).try(:present?) && softwares_setting.try(:is_ibiza_used) && !softwares_setting.try(:is_exact_online_used)
        # Defaut values to avoid exception validation on (state, state_2, and voucher_ref_target)

          software.state                            = 'none'
          software.state_2                          = 'none'
          software.voucher_ref_target               = 'piece_number'

          software.ibiza_id                         = user.try(:ibiza_id)
          software.is_used                          = softwares_setting.try(:is_ibiza_used)
          software.auto_deliver                     = softwares_setting.try(:is_ibiza_auto_deliver) || -1
          software.is_analysis_activated            = softwares_setting.try(:is_ibiza_compta_analysis_activated) || -1
          software.is_analysis_to_validate          = softwares_setting.try(:is_ibiza_analysis_to_validate) || -1
          software.is_auto_updating_accounting_plan = softwares_setting.try(:is_auto_updating_accounting_plan) == 1 ? true : false
      elsif software_name == 'exact_online' && softwares_setting.try(:is_exact_online_used) && !softwares_setting.try(:is_ibiza_used)
        exact_online = ExactOnline.where(user_id: user.id)
        if exact_online
          exact_online                     = exact_online.first

          software.is_used                 = softwares_setting.try(:is_exact_online_used)
          software.auto_deliver            = softwares_setting.try(:is_exact_online_auto_deliver) || -1
          software.encrypted_client_id     = exact_online.encrypted_client_id
          software.encrypted_client_secret = exact_online.encrypted_client_secret
          software.user_name               = exact_online.user_name
          software.full_name               = exact_online.full_name
          software.email                   = exact_online.email
          software.state                   = exact_online.state
          software.encrypted_refresh_token = exact_online.encrypted_refresh_token
          software.encrypted_access_token  = exact_online.encrypted_access_token
          software.token_expires_at        = exact_online.token_expires_at
        end
      elsif software_name == 'csv_descriptor' && softwares_setting.try(:is_csv_descriptor_used)
        csv_descriptor  = CsvDescriptor.where(user_id: user.id)
        if csv_descriptor
          csv_descriptor                         = csv_descriptor.first

          software.is_used                       = softwares_setting.try(:is_csv_descriptor_used)
          software.auto_deliver                  = softwares_setting.try(:is_csv_descriptor_auto_deliver) || -1
          software.use_own_csv_descriptor_format = softwares_setting.try(:use_own_csv_descriptor_format)
          software.comma_as_number_separator     = csv_descriptor.try(:comma_as_number_separator)
          software.directive                     = csv_descriptor.try(:directive)
        end
      else
        software.is_used      = softwares_setting.send("is_#{software_name}_used".to_sym)
        software.auto_deliver = (softwares_setting.send("is_#{software_name}_auto_deliver".to_sym)) || -1
      end

      software.owner = user
      software.save
    end
  end

  def backup
  end
end
