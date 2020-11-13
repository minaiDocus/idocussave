# frozen_string_literal: true

class Admin::DematboxServicesController < Admin::AdminController
  before_action :load_dematbox_service, only: 'destroy'

  # GET /admin/dematbox_services
  def index
    @dematbox_services = DematboxService.order(type: :desc).order(name: :asc)
  end

  # POST /admin/dematbox_services/load_from_external
  def load_from_external
    Dematbox::Refresh.delay.execute

    flash[:notice] = 'Configuration en cours...'

    redirect_to admin_dematbox_services_path
  end

  # DELETE /admin/dematbox_services/:id
  def destroy
    @dematbox_service.destroy

    flash[:notice] = 'Suppression en cours...'

    redirect_to admin_dematbox_services_path
  end

  private

  def load_dematbox_service
    @dematbox_service = DematboxService.find(params[:id])
  end
end
