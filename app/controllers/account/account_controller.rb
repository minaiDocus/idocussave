# -*- encoding : UTF-8 -*-
class Account::AccountController < ApplicationController
  before_filter :login_user!
  before_filter :load_user_and_role
  before_filter :verify_suspension
  before_filter :verify_if_active
  around_filter :catch_error if %w(staging sandbox production test).include?(Rails.env)

  layout 'inner'

protected

  def catch_error
    begin
      yield
    rescue ActionController::UnknownController,
           AbstractController::ActionNotFound,
           Mongoid::Errors::DocumentNotFound,
           ActionController::RoutingError
      respond_to do |format|
        format.html { render '/404', status: 404, layout: 'inner' }
        format.json { render json: { status: :not_found, code: 404 } }
      end
    rescue Budgea::Errors::ServiceUnavailable => e
      Airbrake.notify(e, airbrake_request_data)
      respond_to do |format|
        format.html { render '/503', status: 503, layout: 'inner' }
        format.json { render json: { status: :error, code: 503 } }
      end
    rescue => e
      Airbrake.notify(e, airbrake_request_data)
      respond_to do |format|
        format.html { render '/500', status: 500, layout: 'inner' }
        format.json { render json: { status: :error, code: 500 } }
      end
    end
  rescue ActionController::UnknownFormat
    render status: 400, text: '404'
  end

  def load_user_and_role(name=:@user)
    instance = load_user(name)
    instance.extend_organization_role if instance
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
    @last_kits       = PaperProcess.where(:user_id.in => users.map(&:id)).kits.desc(:updated_at).limit(5)
    @last_receipts   = PaperProcess.where(:user_id.in => users.map(&:id)).receipts.desc(:updated_at).limit(5)
    @last_scanned    = PeriodDocument.where(:user_id.in => users.map(&:id), :scanned_at.nin => [nil]).desc(:scanned_at).limit(5)
    @last_returns    = PaperProcess.where(:user_id.in => users.map(&:id)).returns.desc(:updated_at).limit(5)
    @last_packs      = @user.packs.desc(:updated_at).limit(5)
    @last_temp_packs = @user.temp_packs.not_published.desc(:updated_at).limit(5)
    if @user.is_prescriber && @user.organization.try(:ibiza).try(:is_configured?)
      customers = @user.is_admin ? @user.organization.customers : @user.customers
      @errors = Pack::Report.failed_delivery(customers.map(&:id), 5)
    end
  end
end
