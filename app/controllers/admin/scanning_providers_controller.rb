# frozen_string_literal: true

class Admin::ScanningProvidersController < Admin::AdminController
  before_action :load_scanning_provider, except: %w[index new create]

  # GET /admin/scanning_providers
  def index
    @scanning_providers = ScanningProvider.all.page(params[:page]).per(params[:per_page])
  end

  # GET /admin/scanning_providers/new
  def new
    @scanning_provider = ScanningProvider.new
  end

  # POST /admin/scanning_providers
  def create
    @scanning_provider = ScanningProvider.new(scanning_provider_params)

    if @scanning_provider.save
      flash[:notice] = 'Créé avec succès.'

      redirect_to admin_scanning_provider_path(@scanning_provider)
    else
      render :new
    end
  end

  # GET /admin/scanning_providers/:id/edit
  def edit; end

  # PUT /admin/scanning_providers/:id
  def update
    if @scanning_provider.update(scanning_provider_params)

      flash[:notice] = 'Modifié avec succès.'

      redirect_to admin_scanning_provider_path(@scanning_provider)
    else
      render :edit
    end
  end

  # DELETE /admin/scanning_providers/:id
  def destroy
    @scanning_provider.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_scanning_providers_path
  end

  private

  def load_scanning_provider
    @scanning_provider = ScanningProvider.find(params[:id])
  end

  def scanning_provider_params
    params.require(:scanning_provider).permit(
      :name,
      :code,
      :is_default,
      :customer_tokens
    ).tap do |whitelist|
      whitelist[:addresses_attributes] = params[:scanning_provider][:addresses_attributes].permit!
    end
  end
end
