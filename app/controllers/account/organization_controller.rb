# frozen_string_literal: true

class Account::OrganizationController < ApplicationController
  include Account::Organization::ConfigurationSteps

  layout 'organization'

  before_action :login_user!
  before_action :load_user_and_role
  before_action :verify_if_active
  before_action :verify_suspension
  before_action :verify_if_a_collaborator
  before_action :load_organization
  before_action :apply_membership
  before_action :load_recent_notifications

  protected

  def verify_if_a_collaborator
    unless @user.collaborator?
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def organization_id
    @organization_id ||= controller_name == 'organizations' ? params[:id] : params[:organization_id]
  end

  def load_organization
    if @user.admin?
      @organization = ::Organization.find organization_id
    elsif organization_id.present?
      @membership = Member.find_by!(user_id: @user.id, organization_id: organization_id.to_i)
      @organization = @membership.organization
    else
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def apply_membership
    @user.with_scope @membership, @organization
  end

  def customers
    @user.customers
  end
  helper_method :customers

  def customer_ids
    customers.map(&:id)
  end

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  def multi_organizations?
    (@organization.organization_group&.organizations&.count || 1) > 1
  end
  helper_method :multi_organizations?
end
