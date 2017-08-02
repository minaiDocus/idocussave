# -*- encoding : UTF-8 -*-
class Account::AccountController < ApplicationController
  before_filter :login_user!
  before_filter :load_user_and_role
  before_filter :verify_suspension
  before_filter :verify_if_active
  before_filter :load_recent_notifications

  layout 'inner'

  def index
    users = if @user.is_prescriber && @user.organization
              @user.customers.includes(:organization)
            else
              [@user]
            end

    @last_kits       = PaperProcess.where(user_id: users.map(&:id)).kits.order(updated_at: :desc).includes(:user).limit(5)
    @last_receipts   = PaperProcess.where(user_id: users.map(&:id)).receipts.order(updated_at: :desc).includes(:user).limit(5)
    @last_scanned    = PeriodDocument.where(user_id: users.map(&:id)).where.not(scanned_at: [nil]).order(scanned_at: :desc).includes(:pack).limit(5)
    @last_returns    = PaperProcess.where(user_id: users.map(&:id)).returns.order(updated_at: :desc).includes(:user).limit(5)
    @last_packs      = all_packs.order(updated_at: :desc).limit(5)
    @last_temp_packs = @user.temp_packs.not_published.order(updated_at: :desc).limit(5)

    if @user.is_prescriber && @user.organization.try(:ibiza).try(:is_configured?)
      customers = @user.is_admin ? @user.organization.customers : @user.customers
      @errors = Pack::Report.failed_delivery(customers.pluck(:id), 5)
    end
  end

protected

  def load_user_and_role(name = :@user)
    instance = load_user(name)
    instance.extend_organization_role if instance
  end

  def accounts
    if @user.is_prescriber
      @user.customers.order(code: :asc)
    elsif @user.is_guest
      @user.accounts.order(code: :asc)
    else
      User.where(id: ([@user.id] + @user.accounts.map(&:id))).order(code: :asc)
    end
  end
  helper_method :accounts

  def account_ids
    accounts.map(&:id)
  end
  helper_method :account_ids

private

  def all_packs
    Pack.where(owner_id: account_ids)
  end

  def verify_if_active
    if @user && @user.inactive? && !controller_name.in?(%w(profiles documents))
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_documents_path
    end
  end

  def load_recent_notifications
    @last_notifications = @user.notifications.order(created_at: :desc).limit(5) if @user
  end
end
