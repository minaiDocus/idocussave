# -*- encoding : UTF-8 -*-
class Account::OrganizationController < Account::AccountController
  layout 'organization'

  before_filter :verify_access
  before_filter :load_user_and_role
  before_filter :load_organization
  before_filter :verify_rights, unless: lambda { |c| c.controller_name.in? %w(customers organization_addresses subscriptions) }

protected

  def verify_access
    unless current_user.is_prescriber || current_user.is_admin
      redirect_to account_profile_path, flash: { error: t('authorization.unessessary_rights') }
    end
    true
  end

  def load_organization(name=:@user)
    @organization = instance_variable_get(name).organization
    if !@organization && controller_name != 'organizations' && action_name != 'show'
      redirect_to account_organization_path
    end
  end

  def verify_rights
    unless @organization.authorized?(@user, action_name, controller_name)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

end