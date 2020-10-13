class Api::V2::OperationsController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def create
    operation = Operation.new(operation_params)
    operation.api_name = 'capidocus'

    if ::CreateOperation.new(operation).perform && operation.persisted?
      render json: serializer.new(operation)
    else
      render json: operation.errors, status: :unprocessable_entity
    end
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def operation_params
    params.require(:operation).permit(:bank_account_id, :date, :value_date, :temp_currency, :label, :amount)
  end

  def serializer
    OperationSerializer
  end
end
