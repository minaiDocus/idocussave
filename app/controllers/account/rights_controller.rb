# -*- encoding : UTF-8 -*-
class Account::RightsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_collaborator

  def edit
  end

  def update
    @collaborator.update_attributes(collaborator_params)
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organization_collaborator_path(@collaborator)
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_collaborators?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def collaborator_params
    params.require(:user).permit(:organization_rights_attributes)
  end

  def load_collaborator
    @collaborator = User.find params[:collaborator_id]
  end

end