# frozen_string_literal: true

class Api::Sgi::V1::MappingGeneratorController < SgiApiController
  # GET /api/sgi/v1/mapping_generator/get_json
  def get_json
    render json: { success: true, data: json_content.to_json }, status: 200
  end

  private

  def user
    @user = User.find_by_code(params[:user_code])
    account_book_type = AccountBookType.find_by_user_id(@user.id)
    return @user if account_book_type && account_book_type.entry_type > 0 && @user.active?
  end

  def json_content
    user.accounting_plan.create_json_format if user.accounting_plan
  end

end