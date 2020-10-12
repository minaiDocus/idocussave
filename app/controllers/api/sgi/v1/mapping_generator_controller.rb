# frozen_string_literal: true

class Api::Sgi::V1::MappingGeneratorController < SgiApiController
  # GET /api/sgi/v1/mapping_generator/get_json
  def get_json
    render json: { success: true, data: json_content.to_json }, status: 200
  end

  private

  def user
    account_book_type = AccountBookType.find_by_user_id(params[:user_id])
    _user = User.find(account_book_type.user_id) if account_book_type && account_book_type.entry_type > 0
    return _user if _user.active?
  end

  def json_content
    user.accounting_plan.create_json_format if user.accounting_plan
  end

end