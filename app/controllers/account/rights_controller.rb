# -*- encoding : UTF-8 -*-
class Account::RightsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_collaborator

  def edit
  end

  def update
    @collaborator.update(collaborator_params)
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organization_collaborator_path(@organization, @collaborator, tab: 'authorization')
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_collaborators?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def collaborator_params
    params.require(:user).permit(organization_rights_attributes: [
      :is_groups_management_authorized,
      :is_collaborators_management_authorized,
      :is_customers_management_authorized,
      :is_journals_management_authorized,
      :is_customer_journals_management_authorized
    ])
  end

  def load_collaborator
    @collaborator = @organization.collaborators.find_by_slug! params[:collaborator_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:collaborator_id]) unless @collaborator
  end
end
