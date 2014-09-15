# -*- encoding : UTF-8 -*-
class Account::OrganizationController < Account::AccountController
  layout 'organization'

  before_filter :verify_rights
  before_filter :load_organization

protected

  def verify_rights
    unless @user.is_prescriber || @user.is_admin
      redirect_to account_documents_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def load_organization
    if @user.is_admin
      @organization = Organization.find_by_slug params[:organization_id]
    elsif @user.organization && params[:organization_id] == @user.organization.slug
      @organization = @user.organization
    else
      redirect_to account_documents_path, flash: { error: t('authorization.unessessary_rights') }
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
