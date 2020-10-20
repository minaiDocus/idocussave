class Api::V2::AccountBookTypesController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def index
     account_book_types = User.find(params[:user_id]).account_book_types

     render json: serializer.new(account_book_types)
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def serializer
    AccountBookTypeSerializer
  end
end
