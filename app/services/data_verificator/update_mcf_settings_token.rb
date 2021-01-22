# -*- encoding : UTF-8 -*-
class DataVerificator::UpdateMcfSettingsToken < DataVerificator::DataVerificator
  def execute
    organizations = Organization.active.billed

    messages = []

    counter  = 0

    organizations.each do |organization|
      mcf_setting      = organization.mcf_settings
      old_access_token = mcf_setting.access_token

      if mcf_setting.access_token_expires_at < Time.now
        mcf_setting.refresh
        counter += 1

        mcf_setting.reload

        messages << "organization_name: #{organization.name}, old_access_token: #{old_access_token}, new_access_token: #{mcf_setting.access_token}"
      end      
    end

    {
      title: "UpdateMcfSettingsToken - #{counter} organization(s) updated token",
      type: "table",
      message: messages.join('; ')
    }
  end
end