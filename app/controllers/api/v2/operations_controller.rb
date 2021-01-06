class Api::V2::OperationsController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def create
    result = Transaction::CreateOperation.perform(operation_params.to_h["_json"])

    render json: result, status: :ok
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def operation_params
    params.permit!
  end

  def serializer
    OperationSerializer
  end
end
