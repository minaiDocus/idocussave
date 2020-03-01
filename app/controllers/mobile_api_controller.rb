# frozen_string_literal: true

class MobileApiController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :authenticate_mobile_user
  before_action :load_user_and_role
  before_action :verify_suspension
  before_action :verify_if_active

  respond_to :json

  private

  # Authenticate User by Token
  def authenticate_mobile_user
    @user = User.where(authentication_token: params[:auth_token]).first

    if @user && Devise.secure_compare(@user.get_authentication_token, params[:auth_token])
      sign_in(@user, store: false)
      @user
    end
    authenticate_user!
  end

  def organization_id
    params[:organization_id].present? ? params[:organization_id] : @user.organization.id
  end

  protected

  def has_multiple_accounts?
    accounts.count > 1
  end

  def load_organization
    if @user.admin?
      @organization = ::Organization.find organization_id
    elsif @user.collaborator?
      @membership = Member.find_by!(user_id: @user.id, organization_id: organization_id.to_i)
      @organization = @membership.organization
    else
      @organization = @user.organization
    end
  end

  def apply_membership
    @user.with_scope @membership, @organization if @user.is_a?(Collaborator)
  end

  def customers
    @customers ||= @user.collaborator? || @user.admin? ? @user.customers : [@user]
  end
end
