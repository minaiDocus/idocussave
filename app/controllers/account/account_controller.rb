# -*- encoding : UTF-8 -*-
class Account::AccountController < ApplicationController
  before_filter :login_user!
  before_filter :load_user_and_role
  before_filter :verify_suspension
  before_filter :verify_if_active
  before_filter :load_recent_notifications

  layout 'inner'

  def index
    @last_packs      = all_packs.order(updated_at: :desc).limit(5)
    @last_temp_packs = @user.temp_packs.not_published.order(updated_at: :desc).limit(5)

    load_last_scans unless @user.is_prescriber || !@user.options.try(:is_upload_authorized)

    if @user.is_prescriber && @user.organization.try(:ibiza).try(:is_configured?)
      customers = @user.is_admin ? @user.organization.customers : @user.customers
      @errors = Pack::Report.failed_delivery(customers.pluck(:id), 5)
    end
  end

  def choose_default_summary
    @user.options.update(dashboard_default_summary: params[:service_name])
    redirect_to root_path
  end

  def last_scans
    load_last_scans

    render partial: 'last_scans'
  end

  def last_uploads
    @last_uploads = Rails.cache.fetch ['user', @user.id, 'last_uploads', temp_documents_key] do
      TempDocument.where(user_id: user_ids).upload.order(created_at: :desc).includes(:user, :piece, :temp_pack).limit(10).to_a
    end

    render partial: 'last_uploads'
  end

  def last_dematbox_scans
    @last_dematbox_scans = Rails.cache.fetch ['user', @user.id, 'last_dematbox_scans', temp_documents_key] do
      TempDocument.where(user_id: user_ids).dematbox_scan.order(created_at: :desc).includes(:user, :piece, :temp_pack).limit(10).to_a
    end

    render partial: 'last_dematbox_scans'
  end

  def last_retrieved
    @last_retrieved = Rails.cache.fetch ['user', @user.id, 'last_retrieved', temp_documents_key] do
      TempDocument.where(user_id: user_ids).retrieved.order(created_at: :desc).includes(:user, :piece, :temp_pack).limit(10).to_a
    end

    @last_operations = Rails.cache.fetch ['user', @user.id, 'last_operations', operations_key] do
      Operation.where(user_id: user_ids).order(created_at: :desc).includes(:user, :bank_account).limit(10).to_a
    end

    render partial: 'last_retrieved'
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

private

  def user_ids
    @user_ids ||= accounts.active.map(&:id).sort
  end

  def get_key_for(name)
    timestamps = user_ids.map do |user_id|
      Rails.cache.fetch ['user', user_id, name, 'last_updated_at'] { Time.now.to_i }
    end
    Digest::MD5.hexdigest timestamps.join('-')
  end

  def temp_documents_key
    get_key_for 'temp_documents'
  end

  def operations_key
    get_key_for 'operations'
  end

  def load_last_scans
    @last_kits     = PaperProcess.where(user_id: user_ids).kits.order(updated_at: :desc).includes(:user).limit(5)
    @last_receipts = PaperProcess.where(user_id: user_ids).receipts.order(updated_at: :desc).includes(:user).limit(5)
    @last_scanned  = PeriodDocument.where(user_id: user_ids).where.not(scanned_at: [nil]).order(scanned_at: :desc).includes(:pack).limit(5)
    @last_returns  = PaperProcess.where(user_id: user_ids).returns.order(updated_at: :desc).includes(:user).limit(5)
  end

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
