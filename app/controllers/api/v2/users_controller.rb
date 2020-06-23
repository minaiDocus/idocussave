class Api::V2::UsersController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def jefacture
     users = User.active.where.not(jefacture_account_id: nil)

     render json: serializer.new(users)
  end

  protected
  
  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def serializer
    UserSerializer
  end
end
