# -*- encoding : UTF-8 -*-
class Account::OrganizationController < Account::AccountController
  layout 'organization'

  before_filter :verify_role
  before_filter :load_organization

protected

  def verify_role
    unless @user.is_prescriber
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def load_organization
    if @user.is_admin
      @organization = Organization.find_by_slug params[:organization_id]
      raise Mongoid::Errors::DocumentNotFound.new(Organization, params[:organization_id]) unless @organization
    elsif @user.organization && params[:organization_id] == @user.organization.slug
      @organization = @user.organization
    else
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def is_leader?
    @user == @organization.leader || @user.is_admin
  end
  helper_method :is_leader?

  def customers
    if @user.is_admin
      @organization.customers
    else
      @user.customers
    end
  end

  def customer_ids
    customers.map(&:id)
  end
end
