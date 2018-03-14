class MobileApiController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :authenticate_mobile_user
  before_action :load_user_and_role
  before_action :verify_suspension
  before_action :verify_if_active
  before_action :load_organization

  respond_to :json

  private

  # Authenticate User by Token
  def authenticate_mobile_user
    @user = User.where(authentication_token: params[:auth_token]).first

    if @user && Devise.secure_compare(@user.authentication_token, params[:auth_token])
      sign_in(@user, store: false)
      @user
    end
    authenticate_user!
  end

  protected

  def load_user_and_role(name = :@user)
    super do |collaborator|
      if @user.organization.present?
        collaborator.with_organization_scope(@user.organization)
      end
    end
  end

  def has_multiple_accounts?
    accounts.count > 1 ? true : false
  end

  def load_organization
    @organization = @user.organization
  end

  def customers
    @customers ||= (@user.collaborator? || @user.admin?) ? @user.customers : [@user]
  end
end
