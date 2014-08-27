# -*- encoding : UTF-8 -*-
class Admin::DematboxServicesController < Admin::AdminController
  before_filter :load_dematbox_service, only: 'destroy'

  def index
    @dematbox_services = DematboxService.desc(:type).asc(:name)
  end

  def load_from_external
    DematboxService.delay(priority: 1).load_from_external
    flash[:notice] = 'Configuration en cours...'
    redirect_to admin_dematbox_services_path
  end

  def destroy
    @dematbox_service.destroy
    flash[:notice] = 'Suppression en cours...'
    redirect_to admin_dematbox_services_path
  end

private

  def load_dematbox_service
    @dematbox_service = DematboxService.find params[:id]
  end
end
