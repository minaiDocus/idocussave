# frozen_string_literal: true

class SgiApiController < ApplicationController
  before_action :authenticate_current_user
  before_action :verify_rights

  attr_reader :current_user

  private

  def respond_with_unauthorized
    respond_to do |format|
      format.json { render json: { message: 'Unauthorized' }, status: 401 }
    end
  end

  def authenticate_current_user
    unless authenticate_by_header || authenticate_by_params
      respond_to do |format|
        format.json { render json: { message: 'Invalid API Token' }, status: 401 }
      end
      nil
    end
  end

  def authenticate_by_header
    return true if @current_user

    authenticate_with_http_token do |token|
      @current_user = User.find_by_token(token)
    end
  end

  def authenticate_by_params
    return true if @current_user

    @current_user = User.find_by_token(params[:access_token])
  end

  def verify_rights
    if !@current_user.is_admin
      respond_with_unauthorized
    end
  end
end
