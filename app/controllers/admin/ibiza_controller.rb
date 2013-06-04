# -*- encoding : UTF-8 -*-
class Admin::IbizaController < Admin::AdminController
  before_filter :load_organization
  before_filter :ibiza_params, except: :show

  layout :nil_layout

  def show
    @ibiza = @organization.ibiza || Ibiza.new
  end

  def create
    @organization.ibiza = Ibiza.new ibiza_params
    if @organization.ibiza.save
      flash[:notice] = 'Jeton Ibiza ajouté avec succès.'
    else
      flash[:error] = "Impossible d'ajouter le jeton ibiza."
    end
    redirect_to admin_organization_path(@organization)
  end

  def update
    if @organization.ibiza.update_attributes(ibiza_params)
      flash[:notice] = 'Jeton Ibiza modifié avec succès.'
    else
      flash[:error] = 'Impossible de modifier le jeton Ibiza.'
    end
    redirect_to admin_organization_path(@organization)
  end

private

  def ibiza_params
    params.require(:ibiza).permit!
  end
end