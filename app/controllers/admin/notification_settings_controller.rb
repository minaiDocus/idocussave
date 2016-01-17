# -*- encoding : UTF-8 -*-
class Admin::NotificationSettingsController < Admin::AdminController
  def index
  end

  def edit_error
  end

  def update_error
    Settings.notify_errors_to = params[:notification][:to].split(',').map(&:strip)
    flash[:notice] = 'Modifié avec succès.'
    redirect_to admin_notification_settings_path
  end

  def edit_subscription
  end

  def update_subscription
    Settings.notify_subscription_changes_to = params[:notification][:to].split(',').map(&:strip)
    flash[:notice] = 'Modifié avec succès.'
    redirect_to admin_notification_settings_path
  end

  def edit_dematbox_order
  end

  def update_dematbox_order
    Settings.notify_dematbox_order_to = params[:notification][:to].split(',').map(&:strip)
    flash[:notice] = 'Modifié avec succès.'
    redirect_to admin_notification_settings_path
  end

  def edit_paper_set_order
  end

  def update_paper_set_order
    Settings.notify_paper_set_order_to = params[:notification][:to].split(',').map(&:strip)
    flash[:notice] = 'Modifié avec succès.'
    redirect_to admin_notification_settings_path
  end

  def edit_ibiza
  end

  def update_ibiza
    Settings.notify_ibiza_deliveries_to = params[:notification][:to].split(',').map(&:strip)
    Settings.notify_on_ibiza_delivery   = params[:notification][:type]
    flash[:notice] = 'Modifié avec succès.'
    redirect_to admin_notification_settings_path
  end

  def edit_scans
  end

  def update_scans
    Settings.notify_scans_not_delivered_to = params[:notification][:to].split(',').map(&:strip)
    flash[:notice] = 'Modifié avec succès.'
    redirect_to admin_notification_settings_path
  end
end
