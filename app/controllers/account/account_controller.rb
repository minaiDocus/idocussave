# -*- encoding : UTF-8 -*-
class Account::AccountController < ApplicationController
  before_filter :login_user!
  before_filter :load_user_and_role
  before_filter :verify_suspension
  before_filter :verify_if_active
  around_filter :catch_error if %w(staging sandbox production test).include?(Rails.env)

  layout "inner"

protected

  def catch_error
    begin
      yield
    rescue ActionController::UnknownController,
           AbstractController::ActionNotFound,
           BSON::InvalidObjectId,
           Mongoid::Errors::DocumentNotFound,
           ActionController::RoutingError
      render '/404', status: 404, layout: 'inner'
    rescue Fiduceo::Errors::ServiceUnavailable => e
      Airbrake.notify(e, airbrake_request_data)
      render '/503', status: 503, layout: 'inner'
    rescue => e
      Airbrake.notify(e, airbrake_request_data)
      render '/500', status: 500, layout: 'inner'
    end
  end

  def load_user_and_role(name=:@user)
    instance = load_user(name)
    instance.extend_organization_role if instance
  end

  def load_fiduceo_user_id
    @fiduceo_user_id = @user.fiduceo_id || FiduceoUser.new(@user).create
  end

  def load_bank_accounts
    @bank_accounts = @user.bank_accounts.asc([:bank_name, :number]).map do |bank_account|
      name = [bank_account.retriever.name, bank_account.name, bank_account.number].join(' - ')
      [name, bank_account.fiduceo_id]
    end
    if @bank_accounts.any?
      ids = @bank_accounts.map { |e| e[1] }
      @bank_account_id = params[:bank_account_id] if params[:bank_account_id].in? ids
      @bank_account_id = ids.first unless @bank_account_id
    else
      redirect_to root_path, flash: { error: "Vous n'avez pas de compte bancaire configuré." }
    end
  end

  def fiduceo_client
    @fiduceo_client ||= Fiduceo::Client.new @user.fiduceo_id, cache: true
  end

private

  def verify_if_active
    if @user && @user.inactive? && !controller_name.in?(%w(profiles documents))
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_documents_path
    end
  end

public

  def index
    if @user.is_prescriber && @user.organization
      users = @user.customers
    else
      users = [@user]
    end
    @last_kits     = PaperProcess.where(:user_id.in => users.map(&:id)).kits.desc(:updated_at).limit(5)
    @last_receipts = PaperProcess.where(:user_id.in => users.map(&:id)).receipts.desc(:updated_at).limit(5)
    @last_scanned  = PeriodDocument.where(:user_id.in => users.map(&:id), :scanned_at.nin => [nil]).desc(:scanned_at).limit(5)
    @last_returns  = PaperProcess.where(:user_id.in => users.map(&:id)).returns.desc(:updated_at).limit(5)
    @last_packs    = @user.packs.desc(:updated_at).limit(5)
    @last_tpacks   = @user.temp_packs.not_processed.desc(:updated_at).limit(5)
    if @user.is_prescriber && @user.organization.try(:ibiza).try(:is_configured?)
      customers = @user.is_admin ? @user.organization.customers : @user.customers
      @errors = Pack::Report::Preseizure.collection.group(
        key: [:report_id, :delivery_message],
        cond: { user_id: { '$in' => customers.map(&:id) }, delivery_message: { '$ne' => '', '$exists' => true } },
        initial: { failed_at: 0, count: 0 },
        reduce: "function(current, result) { result.count++; result.failed_at = current.delivery_tried_at; return result; }"
      ).map do |delivery|
        object = OpenStruct.new
        object.date           = delivery['failed_at'].try(:localtime)
        object.name           = Pack::Report.find(delivery['report_id']).name
        object.document_count = delivery['count'].to_i
        object.message        = delivery['delivery_message']
        object
      end.sort! do |a,b|
        b.date <=> a.date
      end
      @errors = @errors[0..4]
    end
  end

end
