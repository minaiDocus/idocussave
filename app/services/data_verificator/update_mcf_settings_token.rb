# -*- encoding : UTF-8 -*-
class DataVerificator::UpdateMcfSettingsToken < DataVerificator::DataVerificator
  def execute
    messages = []
    counter  = 0

    Organization.billed.each do |organization|
      mcf_setting      = organization.mcf_settings
      next if !mcf_setting

      old_access_token = mcf_setting.access_token
      old_expires_at   = mcf_setting.access_token_expires_at

      if mcf_setting.access_token_expires_at.present? && mcf_setting.access_token_expires_at < Time.now
        mcf_setting.refresh
        counter += 1

        mcf_setting.reload

        messages << "organization_code: #{organization.code}, old_access_token: #{old_access_token}, old_expires_at: #{old_expires_at}, new_access_token: #{mcf_setting.access_token}, new_expires_at: #{mcf_setting.access_token_expires_at}"
      end      
    end

    {
      title: "UpdateMcfSettingsToken - #{counter} organization(s) updated token",
      type: "table",
      message: messages.join('; ')
    }
  end
end