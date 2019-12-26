# frozen_string_literal: true

module Admin::NotificationSettingsHelper
  def notification_addresses(addresses)
    Array(addresses).map do |address|
      link_to address, "mailto:#{address}"
    end.join(', ')
  end

  def ibiza_notification_type
    case Settings.first.notify_on_ibiza_delivery
    when 'yes'
      'Tous'
    when 'no'
      'Désactivé'
    when 'error'
      'Erreur uniquement'
    end
  end
end
