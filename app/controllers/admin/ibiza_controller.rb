# -*- encoding : UTF-8 -*-
class Admin::IbizaController < Admin::AdminController
  before_filter :load_user

  layout :nil_layout

  def show
    @ibiza = @user.ibiza || Ibiza.new
  end

  def create
    @user.ibiza = Ibiza.new params[:ibiza]
    if @user.ibiza.save
      flash[:notice] = 'Jeton Ibiza ajouté avec succès.'
    else
      flash[:error] = "Impossible d'ajouter le jeton ibiza."
    end
    redirect_to admin_user_path(@user)
  end

  def update
    if @user.ibiza.update_attributes(params[:ibiza])
      flash[:notice] = 'Jeton Ibiza modifié avec succès.'
    else
      flash[:error] = 'Impossible de modifier le jeton Ibiza.'
    end
    redirect_to admin_user_path(@user)
  end

  private

  def load_user
    @user = User.find params[:user_id]
  end
end