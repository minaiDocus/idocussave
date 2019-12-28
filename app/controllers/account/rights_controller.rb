# frozen_string_literal: true

class Account::RightsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_member

  # GET /account/organizations/:organization_id/collaborators/:collaborator_id/rights/edit
  def edit; end

  # PUT /account/organizations/:organization_id/collaborators/:collaborator_id/rights
  def update
    @member.update(membership_params)
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organization_collaborator_path(@organization, @member, tab: 'authorization')
  end

  private

  def verify_rights
    unless @user.leader? || @user.manage_collaborators?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def membership_params
    params.require(:member).permit(
      :manage_groups,
      :manage_collaborators,
      :manage_customers,
      :manage_journals,
      :manage_customer_journals
    )
  end

  def load_member
    @member = @organization.members.find params[:collaborator_id]
  end
end
