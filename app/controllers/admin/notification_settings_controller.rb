# frozen_string_literal: true

class Admin::NotificationSettingsController < Admin::AdminController
  # GET /admin/notification_settings
  def index; end

  # GET /admin/notification_settings/edit_error
  def edit_error; end

  # POST /admin/notification_settings/update_error
  def update_error
    Settings.update_setting('notify_errors_to', params[:notification][:to].split(',').map(&:strip))

    flash[:notice] = 'Modifié avec succès.'

    redirect_to admin_notification_settings_path
  end

  # GET /admin/notification_settings/edit_dematbox_order
  def edit_dematbox_order; end

  # POST /admin/notification_settings/update_dematbox_order
  def update_dematbox_order
    Settings.update_setting('notify_dematbox_order_to', params[:notification][:to].split(',').map(&:strip))

    flash[:notice] = 'Modifié avec succès.'

    redirect_to admin_notification_settings_path
  end

  # GET /admin/notification_settings/edit_paper_set_order
  def edit_paper_set_order; end

  # POST /admin/notification_settings/update_paper_set_order
  def update_paper_set_order
    Settings.update_setting('notify_paper_set_order_to', params[:notification][:to].split(',').map(&:strip))

    # settings.save

    flash[:notice] = 'Modifié avec succès.'

    redirect_to admin_notification_settings_path
  end

  # GET /admin/notification_settings/edit_ibiza
  def edit_ibiza; end

  # POST /admin/notification_settings/update_ibiza
  def update_ibiza
    Settings.update_setting('notify_on_ibiza_delivery',   params[:notification][:type])
    Settings.update_setting('notify_ibiza_deliveries_to', params[:notification][:to].split(',').map(&:strip))

    flash[:notice] = 'Modifié avec succès.'

    redirect_to admin_notification_settings_path
  end

  # GET /admin/notification_settings/edit_scans
  def edit_scans; end

  # POST /admin/notification_settings/update_scans
  def update_scans
    Settings.update_setting('notify_scans_not_delivered_to', params[:notification][:to].split(',').map(&:strip))

    flash[:notice] = 'Modifié avec succès.'

    redirect_to admin_notification_settings_path
  end
end
