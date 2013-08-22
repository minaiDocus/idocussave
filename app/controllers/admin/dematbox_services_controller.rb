# -*- encoding : UTF-8 -*-
class Admin::DematboxServicesController < Admin::AdminController
  before_filter :load_dematbox_service, except: %w(index load_from_external)

  def index
    @dematbox_services = DematboxService.desc(:type).asc(:name)
  end

  def load_from_external
    DematboxService.delay(priority: 1).load_from_external
    flash[:notice] = 'Configuration en cours...'
    redirect_to admin_dematbox_services_path
  end

  def edit
  end

  def update
    if @dematbox_service.update_attributes(params[:dematbox_service])
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_dematbox_services_path
    else
      render :edit
    end
  end

  def destroy
    @dematbox_service.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_dematbox_services_path
  end

private
  def load_dematbox_service
    @dematbox_service = DematboxService.find params[:id]
  end
end
