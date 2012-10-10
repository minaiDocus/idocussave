# -*- encoding : UTF-8 -*-
class Account::BoxesController < Account::AccountController
  before_filter :box_authorized?
  before_filter :load_box
  
private

  def box_authorized?
    unless current_user.external_file_storage.try("is_box_authorized?")
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Box."
      redirect_to account_profile_path(panel: 'efs_management')
    end
  end

  def load_box
    @box = current_user.external_file_storage.try("the_box")
    unless @box
      @box = TheBox.new
      current_user.find_or_create_external_file_storage.box_basic = @box
      @box.save
    end
  end

public

  def authorize_url
    @box.reset_session
    redirect_to @box.get_authorize_url
  end
  
  def callback
    @box.update_attributes(auth_token: params[:auth_token], is_configured: true)
    flash[:notice] = "Votre compte Box a été configurée avec succès."
    redirect_to account_profile_path(panel: 'efs_management')
  end
end
