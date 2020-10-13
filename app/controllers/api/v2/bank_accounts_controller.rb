class Api::V2::BankAccountsController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def index
     bank_accounts = User.find_by_code(params[:code]).bank_accounts

     render json: serializer.new(bank_accounts)
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def serializer
    BankAccountSerializer
  end
end
