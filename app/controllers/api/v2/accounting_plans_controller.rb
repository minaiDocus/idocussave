class Api::V2::AccountingPlansController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def index
    accounting_plan = User.find(params[:user_id]).accounting_plan

    render json: { providers: serializer.new(accounting_plan.providers), customers: serializer.new(accounting_plan.customers) }
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def serializer
    AccountingPlanItemSerializer
  end
end
