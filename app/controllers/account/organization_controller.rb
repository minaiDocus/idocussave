# -*- encoding : UTF-8 -*-
class Account::OrganizationController < Account::AccountController
  layout 'organization'

  before_filter :load_user_and_role
  before_filter :verify_access
  before_filter :load_organization

protected

  def verify_access
    unless @user.is_prescriber || @user.is_admin
      redirect_to account_documents_path, flash: { error: t('authorization.unessessary_rights') }
    end
    true
  end

  def load_organization(name=:@user)
    @organization = instance_variable_get(name).organization
    if !@organization && controller_name != 'organizations' && action_name != 'show'
      redirect_to account_organization_path
    end
  end

  def is_leader?
    @user == @organization.leader
  end
  helper_method :is_leader?

end