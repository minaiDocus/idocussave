# -*- encoding : UTF-8 -*-
class ComptaController < ApplicationController
  before_filter :authenticate
  before_filter :load_users

  # GET /compta
  def index
  end


  # GET /compta/:user_id
  def show
    @user = @users.find_by_code params[:id]
  end

  private


  def authenticate
    authenticate_or_request_with_http_basic do |name, password|
      compta_operators = [{"username":"gabriel","password":"C0wbjA78"},{"username":"ft","password":"idocompta"}]
      compta_operators.select do |operator|
        'gabriel' == name && 'C0wbjA78' == password
      end.first.present?
    end
  end


  def load_users
    organization_ids = Organization.active.pluck(:id)

    user_ids = AccountBookType.where.not(user_id: nil).compta_processable.distinct(:user_id).pluck(:user_id)
    
    @users = User.where(organization_id: organization_ids, id: user_ids).active.includes(:options)
  end
end
