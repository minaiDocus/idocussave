# -*- encoding : UTF-8 -*-
class Account::IbizaController < Account::AccountController
  before_filter :verify_management_access, :load_user

  def create
    @user.ibiza = Ibiza.new params[:ibiza]
    if @user.ibiza.save
      flash[:success] = 'Créé avec succès.'
    else
      flash[:error] = 'Impossible de créer.'
    end
    redirect_to account_profile_path(panel: params[:panel])
  end

  def update
    if @user.ibiza.update_attributes(params[:ibiza])
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Impossible de modifier.'
    end
    redirect_to account_profile_path(panel: params[:panel])
  end
end