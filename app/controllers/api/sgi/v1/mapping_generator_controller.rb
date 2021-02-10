# frozen_string_literal: true

class Api::Sgi::V1::MappingGeneratorController < SgiApiController
  # GET /api/sgi/v1/mapping_generator/get_json
  def get_json
    render json: { success: true, data: json_content }, status: 200
  end

  private

  def user
    @user = User.find_by_code(params[:user_code])
    return nil if not @user

    account_book_types = @user.account_book_types.compta_processable
    return @user if account_book_types && @user.still_active?
  end

  def json_content
    return {} if not user
    user.accounting_plan.create_json_format if user.accounting_plan
  end

end