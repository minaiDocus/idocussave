class Settings < ApplicationRecord
  serialize :notify_errors_to
  serialize :compta_operators
  serialize :paper_process_operators
  serialize :notify_dematbox_order_to
  serialize :notify_paper_set_order_to
  serialize :notify_ibiza_deliveries_to
  serialize :micro_package_authorized_to
  serialize :notify_scans_not_delivered_to
  serialize :notify_mcf_errors_to


  def self.update_setting(attribute, updated_value)
    setting = Settings.first

    setting.send("#{attribute}=", updated_value)

    setting.save
  end
end
