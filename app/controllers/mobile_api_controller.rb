# -*- encoding : UTF-8 -*-
class MobileApiController < ApplicationController
  protect_from_forgery with: :null_session

  before_filter :authenticate_mobile_user
  
  respond_to :json

  private
    # Authenticate User by Token
    def authenticate_mobile_user()
        @user = User.where(authentication_token: params[:auth_token]).first

        if @user && Devise.secure_compare(@user.authentication_token, params[:auth_token])
           sign_in(@user, store: false)
           @user
        end
        authenticate_user!
    end

  protected

    def load_user_and_role(name = :@user)
      instance = load_user(name)
      instance.extend_organization_role if instance
    end

    def accounts
      if @user
        if @user.is_prescriber
          @user.customers.order(code: :asc)
        elsif @user.is_guest
          @user.accounts.order(code: :asc)
        else
          User.where(id: ([@user.id] + @user.accounts.map(&:id))).order(code: :asc)
        end
      else
        []
      end
    end
    helper_method :accounts

    def account_ids
      accounts.map(&:id)
    end
    helper_method :account_ids

    def all_packs
      Pack.where(owner_id: account_ids)
    end

    def verify_if_active
      if @user && @user.inactive? && !controller_name.in?(%w(profiles documents))
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to account_documents_path
      end
    end

  def has_multiple_accounts?
    accounts.count > 1 ? true : false
  end

  def load_organization
    @organization = @user.organization
  end

  def customers
    if @user.is_admin
      @customers = @organization.customers
    elsif @user.is_prescriber
      @customers = @user.customers
    else
      @customers = [@user]
    end
    @customers || []
  end

end
