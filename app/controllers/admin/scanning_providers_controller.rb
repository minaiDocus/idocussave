# -*- encoding : UTF-8 -*-
class Admin::ScanningProvidersController < Admin::AdminController
  before_filter :load_scanning_provider, except: %w(index new create)

  def index
    @scanning_providers = ScanningProvider.all.page(params[:page]).per(params[:per_page])
  end

  def new
    @scanning_provider = ScanningProvider.new
  end

  def create
    @scanning_provider = ScanningProvider.new params[:scanning_provider]
    if @scanning_provider.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_scanning_provider_path(@scanning_provider)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @scanning_provider.update_attributes(params[:scanning_provider])
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_scanning_provider_path(@scanning_provider)
    else
      render action: 'edit'
    end
  end

  def destroy
    @scanning_provider.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_scanning_providers_path
  end

private

  def load_scanning_provider
    @scanning_provider = ScanningProvider.find_by_slug params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(ScanningProvider, params[:id]) unless @scanning_provider
    @scanning_provider
  end
end
